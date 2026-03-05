locals {
  name_prefix = "${var.environment}-${var.project_name}"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Service"     = "Hyperswitch Application Resources"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )

  # =========================================================================
  # Feature Enablement Flags
  # =========================================================================

  # KMS feature
  kms_enabled = var.kms != {} && (try(var.kms.create, false) || try(var.kms.key_arn, null) != null)
  kms_create  = try(var.kms.create, false)
  kms_key_arn = local.kms_create ? (length(module.kms) > 0 ? module.kms[0].key_arn : null) : try(var.kms.key_arn, null)

  # S3 Dashboard Themes feature
  s3_dashboard_themes_enabled   = var.s3_dashboard_themes != {} && (try(var.s3_dashboard_themes.create, false) || try(var.s3_dashboard_themes.bucket_arn, null) != null)
  s3_dashboard_themes_create    = try(var.s3_dashboard_themes.create, false)
  s3_dashboard_themes_bucket_arn = local.s3_dashboard_themes_create ? (length(module.s3_dashboard_themes) > 0 ? module.s3_dashboard_themes.s3_bucket_arn : null) : try(var.s3_dashboard_themes.bucket_arn, null)

  # S3 File Uploads feature
  s3_file_uploads_enabled   = var.s3_file_uploads != {} && (try(var.s3_file_uploads.create, false) || try(var.s3_file_uploads.bucket_arn, null) != null)
  s3_file_uploads_create    = try(var.s3_file_uploads.create, false)
  s3_file_uploads_bucket_arn = local.s3_file_uploads_create ? (length(module.s3_file_uploads) > 0 ? module.s3_file_uploads.s3_bucket_arn : null) : try(var.s3_file_uploads.bucket_arn, null)

  # SES feature
  ses_enabled = var.ses != {} && try(var.ses.enabled, false)
  ses_role_arn = local.ses_enabled ? try(var.ses.role_arn, null) : null

  # Secrets Manager feature
  secrets_manager_enabled = var.secrets_manager != {} && try(var.secrets_manager.enabled, false)
  secrets_manager_arns    = local.secrets_manager_enabled ? try(var.secrets_manager.secret_arns, []) : []

  # Assume Role feature
  assume_role_enabled    = var.assume_role != {} && try(var.assume_role.enabled, false)
  assume_role_arns       = local.assume_role_enabled ? try(var.assume_role.target_role_arns, []) : []
  assume_role_account_id = local.assume_role_enabled ? try(var.assume_role.account_id, null) : null

  # Lambda feature
  lambda_enabled      = var.lambda != {} && try(var.lambda.enabled, false)
  lambda_function_arns = local.lambda_enabled ? try(var.lambda.function_arns, []) : []

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
}
