locals {
  gcp_sa_name = "${var.project_name}-${var.environment}-hyperswitch-sa"

  name_prefix = "${var.environment}-${var.project_name}-hyperswitch"

  # GCS bucket names are global: the same name in two projects collides, so default names carry a
  # suffix (var.bucket_name_suffix; null = first 6 hex of sha256(project_id), "" = none). Names are
  # capped at 63 characters by trimming only the readable prefix - the role and the suffix always
  # survive, so two buckets of one module can never trim to the same name - and a trailing -/_/.
  # is stripped because bucket names must end with a letter or digit.
  bucket_suffix     = var.bucket_name_suffix != null ? var.bucket_name_suffix : substr(sha256(var.project_id), 0, 6)
  bucket_suffix_sep = local.bucket_suffix == "" ? "" : "-${local.bucket_suffix}"
  bucket_names = {
    for role in ["dashboard-themes", "file-uploads"] : role => "${trim(substr(local.name_prefix, 0, 63 - length(role) - 1 - length(local.bucket_suffix_sep)), "-_.")}-${role}${local.bucket_suffix_sep}"
  }

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

  dashboard_themes_bucket_name = local.gcs_dashboard_themes_enabled ? coalesce(var.gcs_dashboard_themes.bucket_name, local.bucket_names["dashboard-themes"]) : null
  file_uploads_bucket_name     = local.gcs_file_uploads_enabled ? coalesce(var.gcs_file_uploads.bucket_name, local.bucket_names["file-uploads"]) : null
}
