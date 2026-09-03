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

  # var.cluster_name_version's own description covers the full rationale -
  # summary: null (default) preserves the exact pre-existing computed name
  # ("${name_prefix}-gke", no suffix) since google_container_cluster's name
  # is ForceNew (a rename destroys and recreates the whole live cluster).
  # Only appends "-${cluster_name_version}" when explicitly set, unlike the
  # AWS EKS module's cluster_name_version (always appended, default "v1") -
  # that unconditional-append default isn't safe to adopt here retroactively
  # against an already-named live cluster.
  cluster_name = var.cluster_name != null ? var.cluster_name : (
    var.cluster_name_version != null
    ? "${local.name_prefix}-gke-${var.cluster_name_version}"
    : "${local.name_prefix}-gke"
  )

  # var.enable_node_auto_upgrade's own description covers the rationale -
  # this uniformly overrides every pool's individual auto_upgrade key
  # (var.node_pools is a loosely-typed list(map(any)), so a pool could
  # otherwise set its own auto_upgrade independent of this toggle) so
  # there's one real switch, not per-pool config sprawl a future pool
  # could silently omit.
  node_pools = [for p in var.node_pools : merge(p, { auto_upgrade = var.enable_node_auto_upgrade })]
}
