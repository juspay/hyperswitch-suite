locals {
  name_prefix = "${var.environment}-${var.project_name}-redis"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "cache"
      "managed_by"  = "terraform"
    },
    var.labels
  )

  instance_name = var.instance_name != null ? var.instance_name : "${local.name_prefix}-${var.region}"
}
