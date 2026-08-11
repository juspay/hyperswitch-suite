locals {
  name_prefix = "${var.environment}-${var.project_name}-hyperswitch"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "application" = "hyperswitch"
    },
    var.labels
  )

  kms_enabled                  = var.kms != null && var.kms.create
  gcs_dashboard_themes_enabled = var.gcs_dashboard_themes != null && (var.gcs_dashboard_themes.create || var.gcs_dashboard_themes.bucket_name != null)
  gcs_file_uploads_enabled     = var.gcs_file_uploads != null && (var.gcs_file_uploads.create || var.gcs_file_uploads.bucket_name != null)
  smtp_enabled                 = var.smtp_secret_id != null
  secrets_manager_enabled      = length(var.secret_ids) > 0
  lambda_enabled               = var.cloud_functions != null && var.cloud_functions.enabled
  cross_project_enabled        = var.cross_project_assume != null && var.cross_project_assume.enabled

  dashboard_themes_bucket_name = local.gcs_dashboard_themes_enabled ? coalesce(var.gcs_dashboard_themes.bucket_name, "${local.name_prefix}-dashboard-themes") : null
  file_uploads_bucket_name     = local.gcs_file_uploads_enabled ? coalesce(var.gcs_file_uploads.bucket_name, "${local.name_prefix}-file-uploads") : null
}
