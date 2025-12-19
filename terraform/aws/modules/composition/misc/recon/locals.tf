locals {
  name_prefix = "${var.environment}-${var.project_name}-recon"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Service"   = "Hyperswitch Recon"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )
}
