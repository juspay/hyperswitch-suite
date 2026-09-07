locals {
  name_prefix = "${var.environment}-${var.project_name}-gateway-controller"

  gcp_sa_name = "${var.project_name}-${var.environment}-gateway-controller-sa"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "application" = "gateway-controller"
    },
    var.labels
  )
}
