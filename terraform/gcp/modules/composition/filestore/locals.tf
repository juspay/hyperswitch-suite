locals {
  name_prefix = "${var.environment}-${var.project_name}"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "filestore"
      "managed_by"  = "terraform"
    },
    var.labels
  )
}
