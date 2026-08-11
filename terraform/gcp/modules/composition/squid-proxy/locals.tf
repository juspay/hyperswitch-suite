locals {
  name_prefix = "${var.environment}-${var.project_name}-squid"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "squid-proxy"
      "managed_by"  = "terraform"
    },
    var.labels
  )
}
