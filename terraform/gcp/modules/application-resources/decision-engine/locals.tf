locals {
  name_prefix = "${var.environment}-${var.project_name}-decision-engine"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "application" = "decision-engine"
    },
    var.labels
  )

  bucket_name = var.s3_bucket_name != null ? var.s3_bucket_name : "${local.name_prefix}-storage"
}
