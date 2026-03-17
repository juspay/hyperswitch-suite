locals {
  name_prefix = "${var.project_name}-${var.environment}-${var.app_name}"
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      Application = var.app_name
    },
    var.common_tags
  )

  oidc_statements = var.oidc_providers != null ? flatten([
    for provider_key, provider in var.oidc_providers : [
      for cond_idx, condition in provider.conditions : {
        Sid    = "oidc${replace(provider_key, "_", "")}${cond_idx}"
        Effect = "Allow"
        Principal = {
          Federated = provider.provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          (condition.type) = {
            "${regex("^arn:aws:iam::[0-9]+:oidc-provider/(.+)$", provider.provider_arn)[0]}:${condition.claim}" = condition.values
          }
        }
      }
    ]
  ]) : []

  assume_role_statements = var.assume_role_principals != null ? [
    for principal in var.assume_role_principals : {
      Effect = "Allow"
      Principal = {
        (principal.type) = principal.identifiers
      }
      Action = "sts:AssumeRole"
    }
    if length(principal.identifiers) > 0
  ] : []

  trust_policy_statements = concat(
    local.oidc_statements,
    local.assume_role_statements
  )

  trust_policy = {
    Version   = "2012-10-17"
    Statement = concat(var.custom_trust_statements, local.trust_policy_statements)
  }

  s3_bucket_name = var.s3_bucket_name != null ? var.s3_bucket_name : "${local.name_prefix}-logs-storage"
}

variable "custom_trust_statements" {
  description = "Custom trust statements for the IAM role trust policy"
  type        = list(any)
  default     = []
}

resource "aws_iam_role" "this" {
  name                  = var.role_name != null ? var.role_name : "${local.name_prefix}-role"
  description           = var.role_description != null ? var.role_description : "IAM role for ${var.app_name} EKS application"
  path                  = var.role_path
  max_session_duration  = var.max_session_duration
  assume_role_policy    = jsonencode(local.trust_policy)
  force_detach_policies = var.force_detach_policies

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "aws_managed" {
  for_each = toset(var.aws_managed_policy_names)

  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

resource "aws_iam_role_policy_attachment" "customer_managed" {
  for_each = toset(var.customer_managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.name
  policy = each.value
}

# ==============================================================================
# S3 Bucket (Optional) - Using terraform-aws-modules/s3-bucket
# ==============================================================================

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  count = var.create_s3_bucket ? 1 : 0

  bucket = local.s3_bucket_name

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = var.s3_enable_versioning ? {
    enabled = true
  } : {}

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = var.s3_sse_algorithm == "aws:kms" ? {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = var.s3_kms_master_key_id
        } : {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = var.s3_sse_algorithm == "aws:kms" ? true : false
    }
  }

  lifecycle_rule = var.s3_lifecycle_rules

  logging = var.s3_server_access_logging.enabled ? {
    target_bucket = var.s3_server_access_logging.target_bucket
    target_prefix = coalesce(var.s3_server_access_logging.target_prefix, "${data.aws_caller_identity.current.account_id}/${var.region}/${local.s3_bucket_name}/")
  } : {}

  tags = local.common_tags

  force_destroy = var.s3_force_destroy
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "s3_permissions" {
  count = var.create_s3_bucket && var.s3_permissions_policy != null ? 1 : 0

  name   = "s3-permissions"
  role   = aws_iam_role.this.name
  policy = var.s3_permissions_policy
}

# ==============================================================================
# CloudWatch Logs Access (Optional) - For reading AWS service logs (e.g. RDS)
# ==============================================================================

resource "aws_iam_role_policy" "cloudwatch_logs" {
  count = var.cloudwatch_logs_policy != null ? 1 : 0

  name   = "cloudwatch-logs-read"
  role   = aws_iam_role.this.name
  policy = var.cloudwatch_logs_policy
}
