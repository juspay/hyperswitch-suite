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

  # Null (default) appends no suffix: google_container_cluster's name is
  # ForceNew, so a rename would destroy and recreate the live cluster.
  cluster_name = var.cluster_name != null ? var.cluster_name : (
    var.cluster_name_version != null
    ? "${local.name_prefix}-gke-${var.cluster_name_version}"
    : "${local.name_prefix}-gke"
  )

  # Uniformly overrides every pool's own auto_upgrade key, so the toggle is a
  # single switch rather than per-pool config a new pool could silently omit.
  node_pools = [for p in var.node_pools : merge(p, { auto_upgrade = var.enable_node_auto_upgrade })]
}
