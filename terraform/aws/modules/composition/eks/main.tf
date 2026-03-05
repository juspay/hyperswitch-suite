# -----------------------------------------------------------------------------
# Terraform Configuration
# -----------------------------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

# -----------------------------------------------------------------------------
# Local values
# -----------------------------------------------------------------------------
locals {
  # Cluster IAM role name
  cluster_iam_role_name = coalesce(
    var.cluster_iam_role_name,
    "${var.environment}-${var.project_name}-cluster-role"
  )

  # Node group IAM role name
  node_group_iam_role_name = coalesce(
    var.node_group_iam_role_name,
    "${var.environment}-${var.project_name}-node-group-role"
  )

  # Cross-account role name
  cross_account_role_name = coalesce(
    var.cross_account_role_name,
    "${var.environment}-${var.project_name}-cross-account"
  )

  # Determine if we need node group resources
  create_node_groups = length(var.node_groups) > 0

  # Node groups that need a security group created
  node_groups_needing_sg = {
    for k, v in var.node_groups : k => v
    if try(v.create_security_group, false) == true
  }

  # Node groups that need a custom launch template
  node_groups_needing_custom_lt = {
    for k, v in var.node_groups : k => v
    if try(v.create_security_group, false) == true ||
    (try(v.launch_template, null) != null && (
      try(v.launch_template.ami_id, null) != null ||
      try(v.launch_template.additional_security_group_ids, null) != null ||
      try(v.launch_template.block_device_mappings, null) != null ||
      try(v.launch_template.metadata_options, null) != null
    ))
  }

  # SSH Key logic
  ssh_key_name = var.create_ssh_key ? aws_key_pair.node_group[0].key_name : var.ssh_key_name

  # Auto-generate key pair name if not provided
  ssh_key_pair_name = var.ssh_key_name != null ? var.ssh_key_name : "${var.environment}-${var.project_name}-eks-node-key"

  # Resolved AMI ID for EKS nodes (provided or fetched from SSM)
  eks_node_ami_id = var.default_ami_id != null ? var.default_ami_id : (
    local.create_node_groups ? data.aws_ssm_parameter.eks_ami[0].value : null
  )

  # Default metadata options merged with user overrides
  default_metadata = merge({
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }, var.default_metadata_options)
}

# -----------------------------------------------------------------------------
# EKS-Optimized AMI Data Source
# Fetches the latest AL2023 EKS-optimized AMI for the cluster version
# -----------------------------------------------------------------------------
data "aws_ssm_parameter" "eks_ami" {
  count = local.create_node_groups && var.default_ami_id == null ? 1 : 0

  name = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2023/x86_64/standard/recommended/image_id"
}


# -----------------------------------------------------------------------------
# EKS Cluster IAM Role (Optional - can use existing role)
# Policy provided from live layer - no defaults
# -----------------------------------------------------------------------------
resource "aws_iam_role" "cluster" {
  count = var.create_cluster_iam_role ? 1 : 0

  name               = local.cluster_iam_role_name
  assume_role_policy = var.cluster_iam_role_assume_role_policy

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Custom Policy for Cluster IAM Role (Optional)
# Created when cluster_custom_policy_json is provided
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "cluster_custom" {
  count = var.create_cluster_iam_role && var.cluster_custom_policy_json != null ? 1 : 0

  name        = "${var.environment}-${var.project_name}-cluster-custom"
  description = "Custom policy for EKS cluster role"

  policy = var.cluster_custom_policy_json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_custom" {
  count = var.create_cluster_iam_role && var.cluster_custom_policy_json != null ? 1 : 0

  policy_arn = aws_iam_policy.cluster_custom[0].arn
  role       = aws_iam_role.cluster[0].name
}

# -----------------------------------------------------------------------------
# Managed IAM Policy Attachments for Cluster Role
# Attaches policies from cluster_iam_role_policies variable
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "cluster_policies" {
  for_each = var.create_cluster_iam_role ? var.cluster_iam_role_policies : {}

  policy_arn = each.value
  role       = aws_iam_role.cluster[0].name
}

# -----------------------------------------------------------------------------
# EKS Cluster using terraform-aws-modules/eks
# -----------------------------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.environment}-${var.project_name}-cluster-${var.cluster_name_version}"
  cluster_version = var.cluster_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  # Use custom cluster IAM role (created above or provided)
  create_iam_role = false
  iam_role_arn    = var.create_cluster_iam_role ? aws_iam_role.cluster[0].arn : var.cluster_iam_role_arn

  # Cluster endpoint access configuration
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Cluster security group - allow VPN access
  cluster_security_group_additional_rules = {
    vpn_access = {
      description = "Allow VPN CIDR blocks to communicate with the cluster API"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = var.vpn_cidr_blocks
    }
  }

  # EKS Cluster access entries for IAM principals
  access_entries = merge(
    var.cluster_access_entries,
    var.create_cross_account_role ? {
      cross_account = {
        principal_arn = aws_iam_role.cross_account[0].arn
        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    } : {}
  )

  # Disable EKS module's managed node groups - we create our own with shared IAM role
  eks_managed_node_groups = {}

  # KMS encryption configuration
  kms_key_administrators = var.kms_key_administrators

  tags = var.tags
}


# -----------------------------------------------------------------------------
# IAM Role for EBS CSI Driver (IRSA)
# -----------------------------------------------------------------------------
module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"

  role_name = "${var.environment}-${var.project_name}-ebs-csi"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}
