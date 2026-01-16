# ============================================================================
# Local Variables
# ============================================================================

locals {
  name_prefix = "${var.environment}-${var.project_name}-alb-controller"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "alb-controller"
      "ManagedBy"   = "terraform"
    },
    var.common_tags
  )

}
