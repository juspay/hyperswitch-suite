locals {
  gcp_sa_name = "${var.project_name}-${var.environment}-superposition-sa"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "application" = "superposition"
    },
    var.labels
  )
}
