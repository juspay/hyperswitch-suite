locals {
  # ============================================================================
  # OIDC Providers Configuration
  # ============================================================================
  oidc_providers = {
    eks_cluster = {
      provider_arn = var.oidc_provider_arn
      conditions = [
        {
          type   = "StringEquals"
          claim  = "aud"
          values = ["sts.amazonaws.com"]
        },
        {
          type   = "StringEquals"
          claim  = "sub"
          values = ["system:serviceaccount:vector:vector-logging"]
        }
      ]
    }
  }

  # ============================================================================
  # S3 Permissions Policy for Vector Logging
  # ============================================================================
  # This policy grants Vector Logging the necessary permissions to read/write logs to S3
  s3_permissions_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name != null ? var.s3_bucket_name : "hs-${var.environment}-vector-logging-storage"}",
          "arn:aws:s3:::${var.s3_bucket_name != null ? var.s3_bucket_name : "hs-${var.environment}-vector-logging-storage"}/*"
        ]
      }
    ]
  })
}

module "eks_iam" {
  source = "../../../../../modules/application-resources/eks-iam"

  region       = var.region
  environment  = var.environment
  project_name = var.project_name
  app_name     = "vector-logging"
  role_name    = var.role_name

  oidc_providers = local.oidc_providers

  # ============================================================================
  # S3 Bucket Configuration (Optional)
  # ============================================================================
  create_s3_bucket     = var.create_s3_bucket
  s3_bucket_name       = var.s3_bucket_name
  s3_force_destroy     = var.s3_force_destroy
  s3_enable_versioning = var.s3_enable_versioning
  s3_sse_algorithm     = var.s3_sse_algorithm
  s3_kms_master_key_id = var.s3_kms_master_key_id

  # S3 Server Access Logging
  s3_server_access_logging = var.s3_server_access_logging

  # S3 Lifecycle rules (optional - e.g., expire logs after 30 days)
  s3_lifecycle_rules = var.s3_lifecycle_rules

  # S3 permissions policy (passed from live layer)
  s3_permissions_policy = var.create_s3_bucket ? local.s3_permissions_policy : null

  common_tags = var.common_tags
}
