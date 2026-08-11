locals {
  display_name = coalesce(var.display_name, "${var.environment}-${var.project_name}-redis")
}

# ============================================================================
# OCI Cache with Redis cluster - equivalent of the AWS `elasticache`
# composition module (aws_elasticache_replication_group). No verified
# registry module exists - raw oci provider resource.
# ============================================================================
resource "oci_redis_redis_cluster" "this" {
  compartment_id     = var.compartment_id
  display_name       = local.display_name
  software_version   = var.software_version
  node_count         = var.cluster_mode == "SHARDED" ? null : var.node_count
  node_memory_in_gbs = var.node_memory_in_gbs
  cluster_mode       = var.cluster_mode
  shard_count        = var.cluster_mode == "SHARDED" ? var.shard_count : null
  subnet_id          = var.subnet_id
  nsg_ids            = var.nsg_ids

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}
