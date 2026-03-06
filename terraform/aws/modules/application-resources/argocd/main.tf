# ============================================================================
# Data Sources
# ============================================================================

data "aws_caller_identity" "current" {}

# Fetch OIDC provider details for each cluster
data "aws_iam_openid_connect_provider" "oidc" {
  for_each = var.oidc_provider_arns
  arn      = each.value
}

# Policy document for cross-account role assumption
data "aws_iam_policy_document" "cross_account_assume" {
  count = var.create_assume_role_policy && length(var.cross_account_roles) > 0 ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = var.cross_account_roles
  }
}

# ============================================================================
# IAM Role
# ============================================================================

resource "aws_iam_role" "argocd_management" {
  name                 = var.role_name != null ? var.role_name : "${local.name_prefix}-management-role"
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

# Inline policy for cross-account role assumption
resource "aws_iam_role_policy" "cross_account_assume" {
  count = var.create_assume_role_policy && length(var.cross_account_roles) > 0 ? 1 : 0

  name   = "cross-account-assume-role"
  role   = aws_iam_role.argocd_management.id
  policy = data.aws_iam_policy_document.cross_account_assume[0].json
}

# Attach additional managed policies
resource "aws_iam_role_policy_attachment" "additional" {
  for_each = toset(var.additional_policy_arns)

  role       = aws_iam_role.argocd_management.name
  policy_arn = each.value
}
