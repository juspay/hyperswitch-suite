locals {
  name_prefix = "${var.environment}-${var.project_name}"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "managed_by"  = "terraform"
    },
    var.labels
  )

  cluster_name = var.cluster_name != null ? var.cluster_name : "${local.name_prefix}-gke"
}
