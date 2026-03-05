# =============================================================================
# EKS Composition Module - Node Group IAM and Node Groups
# =============================================================================
# All IAM policies MUST be passed from the live layer - no defaults.
# =============================================================================

# -----------------------------------------------------------------------------
# SSH Key Pair (Optional)
# Create or use existing SSH key for node group access
# -----------------------------------------------------------------------------

# Generate private key if create_ssh_key=true and no public_key provided
resource "tls_private_key" "node_group" {
  count     = var.create_ssh_key && var.ssh_public_key == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair (from provided or generated public key)
resource "aws_key_pair" "node_group" {
  count      = var.create_ssh_key ? 1 : 0
  key_name   = local.ssh_key_pair_name
  public_key = var.ssh_public_key != null ? var.ssh_public_key : tls_private_key.node_group[0].public_key_openssh

  tags = merge(var.tags, {
    Name      = local.ssh_key_pair_name
    ManagedBy = "terraform"
  })
}

# Store auto-generated private key in SSM Parameter Store
resource "aws_ssm_parameter" "node_group_private_key" {
  count       = var.create_ssh_key && var.ssh_public_key == null ? 1 : 0
  name        = "/${var.environment}/${var.project_name}/eks/node-group/ssh-private-key"
  description = "Auto-generated SSH private key for EKS node groups"
  type        = "SecureString"
  value       = tls_private_key.node_group[0].private_key_pem

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.project_name}-eks-node-private-key"
  })
}

# -----------------------------------------------------------------------------
# IAM Role for EKS Node Groups
# Single shared role for all node groups (avoids eks module creating one per group)
# Policy provided from live layer - no defaults
# -----------------------------------------------------------------------------
resource "aws_iam_role" "node_group" {
  count = local.create_node_groups && var.create_node_group_iam_role ? 1 : 0

  name               = local.node_group_iam_role_name
  assume_role_policy = var.node_group_iam_role_assume_role_policy

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Managed IAM Policy Attachments (using for_each)
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "node_group_policies" {
  for_each = local.create_node_groups && var.create_node_group_iam_role ? var.node_group_iam_role_policies : {}

  policy_arn = each.value
  role       = aws_iam_role.node_group[0].name
}

# -----------------------------------------------------------------------------
# Custom Policy for Node Group (e.g., Observability)
# Created when node_group_custom_policy_json is provided
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "node_group_custom" {
  count = local.create_node_groups && var.create_node_group_iam_role && var.node_group_custom_policy_json != null ? 1 : 0

  name        = "${var.environment}-${var.project_name}-node-custom"
  description = "Custom policy for EKS nodes"

  policy = var.node_group_custom_policy_json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_group_custom" {
  count = local.create_node_groups && var.create_node_group_iam_role && var.node_group_custom_policy_json != null ? 1 : 0

  policy_arn = aws_iam_policy.node_group_custom[0].arn
  role       = aws_iam_role.node_group[0].name
}

# -----------------------------------------------------------------------------
# Security Groups for Node Groups (Optional)
# Created when create_security_group = true for a node group
# Note: Security group rules are managed separately via aws_security_group_rule
# -----------------------------------------------------------------------------
resource "aws_security_group" "node_group" {
  for_each = local.node_groups_needing_sg

  name        = "${var.environment}-${var.project_name}-${each.key}-sg"
  description = "Security group for ${each.key} node group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name      = "${var.environment}-${var.project_name}-${each.key}-sg"
    NodeGroup = each.key
    ManagedBy = "terraform"
  })
}

# -----------------------------------------------------------------------------
# EKS Managed Node Groups (using for_each with map)
# Created independently from eks module for full control over:
# - Single shared IAM role
# - Custom launch templates per node group
# - Addon sequencing (after critical addons are ready)
# -----------------------------------------------------------------------------
resource "aws_eks_node_group" "custom_nodes" {
  for_each = var.node_groups

  cluster_name           = module.eks.cluster_name
  node_group_name_prefix = "${each.key}-"
  node_role_arn          = var.create_node_group_iam_role ? aws_iam_role.node_group[0].arn : var.node_group_iam_role_arn

  # Use per-node-group subnets if specified, otherwise use cluster subnets
  subnet_ids = try(each.value.subnet_ids, null) != null ? each.value.subnet_ids : var.subnet_ids

  # Instance types for the node group
  instance_types = each.value.instance_types

  # Scaling configuration
  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  # Update configuration
  update_config {
    max_unavailable_percentage = try(each.value.max_unavailable_percentage, 33)
  }

  # Launch template selection
  # - If node group is in node_groups_needing_custom_lt -> use custom template
  # - Otherwise -> use default launch template
  launch_template {
    id      = contains(keys(local.node_groups_needing_custom_lt), each.key) ? aws_launch_template.custom_node_group[each.key].id : aws_launch_template.default[0].id
    version = "$Latest"
  }

  # Capacity type
  capacity_type = try(each.value.capacity_type, "ON_DEMAND")

  # Labels
  labels = try(each.value.labels, {})

  # Tags
  tags = merge(var.tags, try(each.value.tags, {}), {
    Name = "${var.environment}-${var.project_name}-${each.key}"
  })

  # Lifecycle management
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      scaling_config[0].desired_size,
      launch_template[0].version
    ]
  }

  # Ensure node groups are created after:
  # 1. EKS cluster is ready
  # 2. Critical addons (vpc-cni, kube-proxy) are installed
  depends_on = [
    module.eks,
    aws_eks_addon.before_nodes
  ]
}

# # -----------------------------------------------------------------------------
# # EKS Access Entry for Node IAM Role
# # Required for nodes to authenticate with the cluster
# # -----------------------------------------------------------------------------
# resource "aws_eks_access_entry" "node_role" {
#   count = local.create_node_groups && var.create_node_group_iam_role ? 1 : 0

#   cluster_name  = module.eks.cluster_name
#   principal_arn = aws_iam_role.node_group[0].arn
#   type          = "EC2_LINUX"

#   # EC2_LINUX type automatically includes system:nodes group
#   # But for AL2023 bootstrap, we also need system:bootstrappers
#   # This is handled by EKS for EC2_LINUX type

#   tags = var.tags

#   depends_on = [module.eks]
# }
