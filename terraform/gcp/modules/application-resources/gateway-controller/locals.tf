locals {
  name_prefix = "${var.environment}-${var.project_name}-gateway-controller"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "application" = "gateway-controller"
    },
    var.labels
  )
}
