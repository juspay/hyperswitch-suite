locals {
  name_prefix = "${var.environment}-${var.project_name}-${var.app_name}"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Application" = var.app_name
      "Service"     = "Vector Application"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )

  # =========================================================================
  # Feature Enablement Flags
  # =========================================================================

  # OIDC/IRSA feature
  oidc_enabled = length(var.cluster_service_accounts) > 0

  # Assume role principals feature
  assume_role_principals_enabled = length(var.assume_role_principals) > 0

  # AWS managed policies feature
  aws_managed_policies_enabled = length(var.aws_managed_policy_names) > 0

  # Customer managed policies feature
  customer_managed_policies_enabled = length(var.customer_managed_policy_arns) > 0

  # S3 bucket feature
  s3_enabled    = var.s3 != {} && (try(var.s3.create, false) || try(var.s3.bucket_arn, null) != null)
  s3_create     = try(var.s3.create, false)
  s3_bucket_arn = local.s3_create ? (length(module.s3_bucket) > 0 ? module.s3_bucket[0].s3_bucket_arn : null) : try(var.s3.bucket_arn, null)

  # =========================================================================
  # OIDC Configuration
  # =========================================================================
  cluster_oidc_statements = {
    for cluster_name, service_accounts in var.cluster_service_accounts : cluster_name => {
      oidc_arn = data.aws_iam_openid_connect_provider.oidc[cluster_name].arn
      oidc_url = data.aws_iam_openid_connect_provider.oidc[cluster_name].url
      subjects = [
        for sa in service_accounts : "system:serviceaccount:${sa.namespace}:${sa.name}"
      ]
    }
  }

  # =========================================================================
  # S3 Bucket Configuration
  # =========================================================================
  s3_bucket_name = local.s3_create ? (try(var.s3.bucket_name, null) != null ? var.s3.bucket_name : "${local.name_prefix}-logs-storage") : null
}
