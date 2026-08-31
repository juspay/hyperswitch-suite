locals {
  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "application" = "superposition"
    },
    var.labels
  )
}
