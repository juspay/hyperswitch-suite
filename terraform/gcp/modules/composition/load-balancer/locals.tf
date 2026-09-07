locals {
  name_prefix = "${var.environment}-${var.project_name}-${var.name_override}"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "managed_by"  = "terraform"
    },
    var.labels
  )
}
