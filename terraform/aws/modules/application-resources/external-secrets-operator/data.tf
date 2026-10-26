# =========================================================================
# DATA SOURCES
# =========================================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# =========================================================================
# IAM POLICY DOCUMENTS
# =========================================================================

data "aws_iam_policy_document" "secrets_manager_access" {
  statement {
    sid    = "SecretsManagerAccess"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "arn:aws:secretsmanager:${var.region}:${var.aws_account_id}:secret:*"
    ]
  }
}
