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

  # Classic Memorystore instance IDs: 1-40 chars, lowercase letters, digits and
  # hyphens, starting with a letter.
  instance_id = var.instance_id != null ? var.instance_id : "${local.name_prefix}-${var.region}"

  read_replicas_enabled = var.tier == "STANDARD_HA" && var.read_replica_count > 0

  # BASIC has no replicas at all; STANDARD_HA has its one standby (1) unless
  # read replicas are enabled, in which case it is the number of read replicas.
  replica_count = var.tier == "BASIC" ? 0 : (local.read_replicas_enabled ? var.read_replica_count : 1)
}
