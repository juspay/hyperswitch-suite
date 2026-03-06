# ============================================================================
# IAM Role
# ============================================================================

resource "aws_iam_role" "external_secrets" {
  name                 = var.role_name != null ? var.role_name : "${local.name_prefix}-role"
  description          = var.role_description
  path                 = var.role_path
  max_session_duration = var.max_session_duration
  assume_role_policy   = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
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
      var.additional_assume_role_statements
    )
  })

  tags = local.common_tags
}

# ============================================================================
# IAM Policies
# ============================================================================

# Inline policy for Secrets Manager access
resource "aws_iam_role_policy" "secrets_manager_access" {
  name   = "secrets-manager-access"
  role   = aws_iam_role.external_secrets.id
  policy = data.aws_iam_policy_document.secrets_manager_access.json
}

# Attach additional managed policies
resource "aws_iam_role_policy_attachment" "additional" {
  for_each = toset(var.additional_policy_arns)

  role       = aws_iam_role.external_secrets.name
  policy_arn = each.value
}
