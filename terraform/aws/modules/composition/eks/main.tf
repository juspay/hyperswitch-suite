# Custom IAM Role for EKS Cluster with optional ArgoCD trust policy
resource "aws_iam_role" "cluster" {
  count = var.create ? 1 : 0

  name = "${var.environment}-${var.project_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Principal = {
            Service = "eks.amazonaws.com"
          }
          Action = "sts:AssumeRole"
        }
      ],
      var.argocd_assume_role_principal_arn != null ? [
        {
          Effect = "Allow"
          Principal = {
            AWS = var.argocd_assume_role_principal_arn
          }
          Action = "sts:AssumeRole"
        }
      ] : []
    )
  })

  tags = var.tags
}

# Attach required EKS cluster policy
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  count = var.create ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster[0].name
}

# EKS Cluster using terraform-aws-modules/eks
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  create = var.create

  cluster_name    = "${var.environment}-${var.project_name}-cluster-${var.cluster_name_version}"
  cluster_version = var.cluster_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  # Use custom cluster IAM role with ArgoCD trust policy
  create_iam_role = false
  iam_role_arn    = aws_iam_role.cluster.arn

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
  access_entries = var.cluster_access_entries

  # EKS Managed Node Groups
  eks_managed_node_groups = var.node_groups

  # KMS encryption configuration
  kms_key_administrators = var.kms_key_administrators

  tags = var.tags
}

# IAM Role for Cluster Autoscaler (IRSA)
module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"

  role_name = "${var.environment}-${var.project_name}-cluster-autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }

  tags = var.tags
}

# IAM Role for EBS CSI Driver (IRSA - IAM Roles for Service Accounts)
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