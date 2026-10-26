locals {
  gcp_sa_name = "${var.project_name}-${var.environment}-grafana-sa"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "application" = "grafana"
    },
    var.labels
  )
}
