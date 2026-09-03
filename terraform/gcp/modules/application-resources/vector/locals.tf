locals {
  gcp_sa_name = "${var.project_name}-${var.environment}-vector-sa"

  name_prefix = "${var.environment}-${var.project_name}-vector"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "application" = "vector"
    },
    var.labels
  )

  bucket_name = var.bucket_name != null ? var.bucket_name : "${local.name_prefix}-logs"
}
