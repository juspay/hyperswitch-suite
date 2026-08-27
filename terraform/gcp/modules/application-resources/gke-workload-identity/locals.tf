locals {
  name_prefix = "${var.project_name}-${var.environment}-${var.app_name}"

  common_labels = merge(
    {
      "project"     = var.project_name
      "environment" = var.environment
      "application" = var.app_name
    },
    var.labels
  )

  gcp_sa_name = var.service_account_id != null ? var.service_account_id : "${local.name_prefix}-sa"
  bucket_name = var.bucket_name != null ? var.bucket_name : "${local.name_prefix}-storage"
}
