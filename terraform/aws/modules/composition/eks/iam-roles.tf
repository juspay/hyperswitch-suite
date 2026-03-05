# =============================================================================
# EKS Composition Module - IAM Roles (Cross-Account / Management)
# =============================================================================
# This file contains optional IAM roles for cross-account access patterns.
# All configurations MUST be passed from the live layer - no defaults.
# =============================================================================

# -----------------------------------------------------------------------------
# IAM Role for Cross-Account Access (e.g., ArgoCD, Atlantis, CI/CD)
# Allows external principals to access this EKS cluster
# -----------------------------------------------------------------------------
resource "aws_iam_role" "cross_account" {
  count = var.create_cross_account_role ? 1 : 0

  name               = local.cross_account_role_name
  assume_role_policy = var.cross_account_assume_role_policy

  tags = var.tags
}

# -----------------------------------------------------------------------------
# IAM Policy for Cross-Account Access (Custom Policy JSON)
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "cross_account" {
  count = var.create_cross_account_role && var.cross_account_policy_json != null ? 1 : 0

  name        = "${var.environment}-${var.project_name}-cross-account-access"
  description = "Policy for cross-account EKS access"

  policy = var.cross_account_policy_json

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Attach custom policy to cross-account role
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "cross_account_custom" {
  count = var.create_cross_account_role && var.cross_account_policy_json != null ? 1 : 0

  role       = aws_iam_role.cross_account[0].name
  policy_arn = aws_iam_policy.cross_account[0].arn
}

# -----------------------------------------------------------------------------
# Attach additional policy ARNs to cross-account role
# For when you want to use existing managed policies
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "cross_account_policy_arns" {
  count = var.create_cross_account_role ? length(var.cross_account_policy_arns) : 0

  role       = aws_iam_role.cross_account[0].name
  policy_arn = var.cross_account_policy_arns[count.index]
}
