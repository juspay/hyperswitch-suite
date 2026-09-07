locals {
  name_prefix = "${var.environment}-${var.project_name}-backend"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "terraform-backend"
      "managed_by"  = "terraform"
    },
    var.labels
  )
}
