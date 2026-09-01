locals {
  name_prefix = "${var.environment}-${var.project_name}-cdn"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "cloud-cdn"
      "managed_by"  = "terraform"
    },
    var.labels
  )
}
