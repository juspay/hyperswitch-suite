locals {
  name_prefix = "${var.environment}-${var.project_name}-alb"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "load-balancer"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )

  lb_name = var.name != null ? var.name : local.name_prefix
}
