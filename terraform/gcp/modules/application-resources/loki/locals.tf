locals {
  name_prefix = "${var.environment}-${var.project_name}-loki"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "application" = "loki"
    },
    var.labels
  )

  bucket_name = var.bucket_name != null ? var.bucket_name : "${local.name_prefix}-chunks"
}
