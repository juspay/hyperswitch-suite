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
# IAM - S3 POLICY
# =========================================================================
resource "aws_iam_policy" "s3_policy" {
  count = local.s3_enabled ? 1 : 0

  name = "${local.name_prefix}-s3-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3Access"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "${local.s3_bucket_arn}/*",
          local.s3_bucket_arn
        ]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  count = local.s3_enabled ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.s3_policy[0].arn
}

# =========================================================================
# S3 BUCKET (Optional)
# =========================================================================
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  count = local.s3_create ? 1 : 0

  bucket = local.s3_bucket_name

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = try(var.s3.versioning_enabled, false) ? {
    enabled = true
  } : {}

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
  }

  transition_default_minimum_object_size = try(var.s3.transition_default_minimum_object_size, null)

  lifecycle_rule = try(var.s3.lifecycle_rules, null) != null ? var.s3.lifecycle_rules : try(var.s3.lifecycle_rule, [])

  tags = local.common_tags

  force_destroy = try(var.s3.force_destroy, false)
}

# =========================================================================
# SECURITY GROUP (Optional)
# =========================================================================
resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name        = var.security_group_name != null ? var.security_group_name : "${local.name_prefix}-alb-sg"
  description = var.security_group_description
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = var.security_group_name != null ? var.security_group_name : "${local.name_prefix}-alb-sg"
    }
  )
}

# =========================================================================
# SECURITY GROUP INGRESS RULES
# =========================================================================
resource "aws_security_group_rule" "ingress" {
  for_each = var.create_security_group ? { for idx, rule in var.security_group_ingress_rules : idx => rule } : {}

  type                     = "ingress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.source_security_group_id
  prefix_list_ids          = each.value.prefix_list_ids
  description              = each.value.description
  security_group_id        = aws_security_group.this[0].id
}

# =========================================================================
# SECURITY GROUP EGRESS RULES (LB to EKS nodes)
# =========================================================================
resource "aws_security_group_rule" "egress" {
  for_each = var.create_security_group ? { for idx, rule in var.security_group_egress_rules : idx => rule } : {}

  type                     = "egress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.source_security_group_id
  prefix_list_ids          = each.value.prefix_list_ids
  description              = each.value.description
  security_group_id        = aws_security_group.this[0].id
}

# =========================================================================
# SECURITY GROUP EGRESS RULES (LB to EKS nodes - automatic)
# =========================================================================
resource "aws_security_group_rule" "lb_egress_to_eks" {
  count = var.create_security_group && var.vpc_id != null && var.eks_node_security_group_id != null ? 1 : 0

  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = var.eks_node_security_group_id
  description              = "HTTP to EKS worker nodes"
  security_group_id        = aws_security_group.this[0].id
}

# =========================================================================
# EKS NODE SECURITY GROUP INGRESS RULES (Allow traffic from Loki LB)
# =========================================================================
resource "aws_security_group_rule" "eks_ingress_from_loki" {
  count = var.eks_node_security_group_id != null ? 1 : 0

  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.this[0].id
  description              = "HTTP from Loki LB"
  security_group_id        = var.eks_node_security_group_id
}
