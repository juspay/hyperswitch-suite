locals {
  name_prefix = "${var.environment}-${var.project_name}-redis"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "cache"
      "engine"      = "redis"
      "managed_by"  = "terraform"
    },
    var.labels
  )

  instance_id     = var.instance_id != null ? var.instance_id : "${local.name_prefix}-${var.region}"
  network_project = var.network_project != null ? var.network_project : var.project_id
}
