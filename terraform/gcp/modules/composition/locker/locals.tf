locals {
  name_prefix = "${var.environment}-${var.project_name}-locker"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "locker"
      "managed_by"  = "terraform"
    },
    var.labels
  )
}
