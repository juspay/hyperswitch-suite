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
      length([for sa in provider.service_accounts : sa if sa.condition_type == "StringEquals" || sa.condition_type == null]) > 0 ? [
        {
          Sid    = "oidc${replace(provider_key, "_", "")}eq"
          Effect = "Allow"
          Principal = {
            Federated = provider.provider_arn
          }
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "${replace(provider.provider_arn, "arn:aws:iam::[0-9]+:oidc-provider/", "")}:sub" = flatten([
                for sa in provider.service_accounts : sa.condition_value != null ? sa.condition_value : ["system:serviceaccount:${sa.namespace}:${sa.name}"]
                if sa.condition_type == "StringEquals" || sa.condition_type == null
              ])
            }
          }
        }
      ] : [],
      length([for sa in provider.service_accounts : sa if sa.condition_type == "StringLike"]) > 0 ? [
        {
          Sid    = "oidc${replace(provider_key, "_", "")}like"
          Effect = "Allow"
          Principal = {
            Federated = provider.provider_arn
          }
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringLike = {
              "${replace(provider.provider_arn, "arn:aws:iam::[0-9]+:oidc-provider/", "")}:sub" = flatten([
                for sa in provider.service_accounts : sa.condition_value != null ? sa.condition_value : ["system:serviceaccount:${sa.namespace}:${sa.name}"]
                if sa.condition_type == "StringLike"
              ])
            }
          }
        }
      ] : []
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

output "role_name" {
  description = "Name of the created IAM role"
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "ARN of the created IAM role"
  value       = aws_iam_role.this.arn
}

output "role_id" {
  description = "ID of the created IAM role"
  value       = aws_iam_role.this.id
}
