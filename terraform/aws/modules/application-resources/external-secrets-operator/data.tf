# =========================================================================
# DATA SOURCES
# =========================================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_eks_cluster" "eks" {
  for_each = var.cluster_service_accounts
  name     = each.key
}

data "aws_iam_openid_connect_provider" "oidc" {
  for_each = data.aws_eks_cluster.eks
  url      = each.value.identity[0].oidc[0].issuer
}

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
