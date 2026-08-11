locals {
  name_prefix = "${var.environment}-${var.project_name}-envoy"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "envoy-proxy"
      "managed_by"  = "terraform"
    },
    var.labels
  )
}
