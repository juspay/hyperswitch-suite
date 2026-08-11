locals {
  name_prefix = "${var.environment}-${var.project_name}-kafka"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "kafka"
      "managed_by"  = "terraform"
    },
    var.labels
  )
}
