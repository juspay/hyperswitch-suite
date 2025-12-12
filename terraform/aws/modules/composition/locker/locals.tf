locals {
  name_prefix = "${var.environment}-${var.project_name}-locker"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "locker"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )

}