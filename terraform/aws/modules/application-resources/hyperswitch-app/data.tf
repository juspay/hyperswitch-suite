# =========================================================================
# DATA SOURCES
# =========================================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# EKS Cluster data for OIDC
# =========================================================================
data "aws_eks_cluster" "eks" {
  for_each = var.cluster_service_accounts
  name     = each.key
}

data "aws_iam_openid_connect_provider" "oidc" {
  for_each = data.aws_eks_cluster.eks
  url      = each.value.identity[0].oidc[0].issuer
}

# KMS Key data (for existing keys)
# =========================================================================
data "aws_kms_key" "existing" {
  count = local.kms_enabled && !local.kms_create ? 1 : 0
  key_id = local.kms_key_arn
}

# S3 Bucket data (for existing buckets)
# =========================================================================
data "aws_s3_bucket" "dashboard_themes" {
  count  = local.s3_dashboard_themes_enabled && !local.s3_dashboard_themes_create ? 1 : 0
  bucket = replace(local.s3_dashboard_themes_bucket_arn, "arn:aws:s3:::", "")
}

data "aws_s3_bucket" "file_uploads" {
  count  = local.s3_file_uploads_enabled && !local.s3_file_uploads_create ? 1 : 0
  bucket = replace(local.s3_file_uploads_bucket_arn, "arn:aws:s3:::", "")
}
