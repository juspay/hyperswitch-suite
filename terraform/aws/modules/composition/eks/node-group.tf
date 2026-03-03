# =============================================================================
# EKS Composition Module - Node Group IAM and Node Groups
# =============================================================================

# -----------------------------------------------------------------------------
# Default Observability Policy (used when node_group_custom_policy = "default")
# -----------------------------------------------------------------------------
locals {
  default_observability_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsObservability"
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetInsightRuleReport",
          "logs:DescribeLogGroups",
          "logs:GetLogGroupFields",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults",
          "logs:GetLogEvents",
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "tag:GetResources"
        ]
        Resource = "*"
      }
    ]
  })

  # Determine if we need node group resources
  create_node_groups = length(var.node_groups) > 0

  # Node groups that need a security group created
  node_groups_needing_sg = {
    for k, v in var.node_groups : k => v
    if try(v.create_security_group, false) == true
  }

  # Node groups that need a custom launch template:
  # - Has create_security_group = true
  # - Has custom ami_id
  # - Has additional_security_group_ids
  # - Has custom block_device_mappings
  # - Has custom metadata_options
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

  # SSH Key logic:
  # - If create_ssh_key = true, use created key
  # - Otherwise, use provided ssh_key_name
  ssh_key_name = var.create_ssh_key ? aws_key_pair.node_group[0].key_name : var.ssh_key_name

  # Auto-generate key pair name if not provided
  ssh_key_pair_name = var.ssh_key_name != null ? var.ssh_key_name : "${var.environment}-${var.project_name}-eks-node-key"

  # Default metadata options merged with user overrides
  default_metadata = merge({
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }, var.default_metadata_options)
}

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
# -----------------------------------------------------------------------------
resource "aws_iam_role" "node_group" {
  count = local.create_node_groups ? 1 : 0

  name = coalesce(var.node_group_iam_role_name, "${var.environment}-${var.project_name}-node-group-role")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Managed IAM Policy Attachments (using for_each)
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "node_group_policies" {
  for_each = local.create_node_groups ? var.node_group_iam_policies : {}

  policy_arn = each.value
  role       = aws_iam_role.node_group[0].name
}

# -----------------------------------------------------------------------------
# Custom Observability Policy (optional)
# Created when node_group_custom_policy is set to "default" or custom JSON
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "node_group_observability" {
  count = local.create_node_groups && var.node_group_custom_policy != null ? 1 : 0

  name        = "${var.environment}-${var.project_name}-node-observability"
  description = "Enhanced observability permissions for EKS nodes"

  policy = var.node_group_custom_policy == "default" ? local.default_observability_policy : var.node_group_custom_policy

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_group_observability" {
  count = local.create_node_groups && var.node_group_custom_policy != null ? 1 : 0

  policy_arn = aws_iam_policy.node_group_observability[0].arn
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
  node_role_arn          = aws_iam_role.node_group[0].arn

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
