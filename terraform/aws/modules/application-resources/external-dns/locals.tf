# ============================================================================
# Local Variables
# ============================================================================

locals {
  name_prefix = "${var.environment}-${var.project_name}-external-dns"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "external-dns"
      "ManagedBy"   = "terraform"
    },
    var.common_tags
  )

}
