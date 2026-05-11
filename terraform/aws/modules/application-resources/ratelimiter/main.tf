# =========================================================================
# IAM - ROLE
# =========================================================================
resource "aws_iam_role" "this" {
  name                  = var.role_name != null ? var.role_name : "${local.name_prefix}-role"
  description           = var.role_description != null ? var.role_description : "IAM role for ${title(var.app_name)} ${title(var.environment)} application"
  path                  = var.role_path
  max_session_duration  = var.max_session_duration
  force_detach_policies = var.force_detach_policies

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # OIDC trust relationships for EKS IRSA
      [
        for cluster_name, statement in local.cluster_oidc_statements : {
          Effect = "Allow"
          Principal = {
            Federated = statement.oidc_arn
          }
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "${statement.oidc_url}:aud" = "sts.amazonaws.com"
              "${statement.oidc_url}:sub" = statement.subjects
            }
          }
        }
      ],
      # Additional AWS principal trust relationships
      local.assume_role_principals_enabled ? [
        {
          Effect = "Allow"
          Principal = {
            AWS = var.assume_role_principals
          }
          Action = "sts:AssumeRole"
        }
      ] : [],
      # Additional custom trust statements
      var.additional_assume_role_statements
    )
  })

  tags = local.common_tags
}

# =========================================================================
# IAM - AWS MANAGED POLICY ATTACHMENTS
# =========================================================================
resource "aws_iam_role_policy_attachment" "aws_managed" {
  for_each = local.aws_managed_policies_enabled ? toset(var.aws_managed_policy_names) : toset([])

  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

# =========================================================================
# IAM - CUSTOMER MANAGED POLICY ATTACHMENTS
# =========================================================================
resource "aws_iam_role_policy_attachment" "customer_managed" {
  for_each = local.customer_managed_policies_enabled ? toset(var.customer_managed_policy_arns) : toset([])

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# =========================================================================
# IAM - INLINE POLICIES
# =========================================================================
resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.name
  policy = each.value
}

# =========================================================================
# ElastiCache for Rate Limiter
# =========================================================================
module "elasticache" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/elasticache?ref=elasticache-v0.1.4"
  count  = local.elasticache_enabled ? 1 : 0

  environment  = var.environment
  project_name = "${var.project_name}-${var.app_name}"
  vpc_id       = var.vpc_id
  subnet_ids   = var.elasticache_config.subnet_ids
  tags         = local.common_tags

  # Engine Configuration
  elasticache_replication_group_id = var.elasticache_config.elasticache_replication_group_id
  engine                           = var.elasticache_config.engine
  engine_version                   = var.elasticache_config.engine_version
  parameter_group_name             = var.elasticache_config.parameter_group_name
  port                             = var.elasticache_config.port

  # Node Configuration
  node_type               = var.elasticache_config.node_type
  num_cache_clusters      = var.elasticache_config.num_cache_clusters
  num_node_groups         = var.elasticache_config.num_node_groups
  replicas_per_node_group = var.elasticache_config.replicas_per_node_group

  # Cluster Mode
  cluster_mode = var.elasticache_config.cluster_mode

  # High Availability
  automatic_failover_enabled = var.elasticache_config.automatic_failover_enabled
  multi_az_enabled           = var.elasticache_config.multi_az_enabled

  # Security
  at_rest_encryption_enabled = var.elasticache_config.at_rest_encryption_enabled
  transit_encryption_enabled = var.elasticache_config.transit_encryption_enabled
  auth_token                 = var.elasticache_config.auth_token

  # Subnet and Security Group
  create_elasticache_subnet_group = var.elasticache_config.create_subnet_group
  elasticache_subnet_group_name   = var.elasticache_config.subnet_group_name
  create_security_group           = var.elasticache_config.create_security_group
  existing_security_group_ids     = var.elasticache_config.create_security_group ? [] : var.elasticache_config.existing_security_group_ids

  # Maintenance & Backup
  maintenance_window       = var.elasticache_config.maintenance_window
  snapshot_window          = var.elasticache_config.snapshot_window
  snapshot_retention_limit = var.elasticache_config.snapshot_retention_limit
  apply_immediately        = var.elasticache_config.apply_immediately
}

# =========================================================================
# Load Balancer Security Group
# =========================================================================
resource "aws_security_group" "lb" {
  count       = local.lb_security_group_enabled ? 1 : 0
  name        = var.lb_security_group_name != null ? var.lb_security_group_name : "${local.name_prefix}-lb-sg"
  description = var.lb_security_group_description
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = merge(
    local.common_tags,
    {
      Name = var.lb_security_group_name != null ? var.lb_security_group_name : "${local.name_prefix}-lb-sg"
    }
  )
}

# =========================================================================
# Load Balancer Security Group Rules - Ingress
# =========================================================================
resource "aws_security_group_rule" "lb_ingress" {
  for_each = local.lb_security_group_enabled ? var.lb_ingress_rules : {}

  security_group_id = aws_security_group.lb[0].id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
}

# =========================================================================
# Load Balancer Security Group Rules - Egress
# =========================================================================
resource "aws_security_group_rule" "lb_egress" {
  for_each = local.lb_security_group_enabled ? var.lb_egress_rules : {}

  security_group_id = aws_security_group.lb[0].id
  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
}
