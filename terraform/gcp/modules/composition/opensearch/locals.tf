locals {
  name_prefix = "${var.environment}-${var.project_name}-opensearch"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "opensearch"
      "managed_by"  = "terraform"
    },
    var.labels
  )
}
