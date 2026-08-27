locals {
  name_prefix = "${var.environment}-${var.project_name}-cassandra"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "cassandra"
      "managed_by"  = "terraform"
    },
    var.labels
  )
}
