locals {
  name_prefix = "${var.environment}-${var.project_name}-clickhouse"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "clickhouse"
      "managed_by"  = "terraform"
    },
    var.labels
  )
}
