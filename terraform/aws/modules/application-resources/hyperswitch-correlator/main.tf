# Standalone hyperswitch-correlator Valkey module.
#
# Self-contained — does NOT call the composition/elasticache module. Only the
# subset of elasticache features the correlator workload actually uses is
# implemented here:
#   - Single-node Valkey replication group (cluster mode disabled)
#   - Dedicated subnet group and security group (always created)
#   - At-rest encryption, no transit encryption
#   - IPV4 only
#   - No global replication, no auth token, no log delivery, no cluster mode
#
# Anything beyond this (e.g. S3 buckets, KMS keys, additional data stores for
# the correlator service) should be added directly to this module without
# touching the shared composition/elasticache module.

locals {
  name_prefix = "${var.environment}-event-correlator-elasticache"

  replication_group_id = "hyperswitch-correlator-valkey"
  subnet_group_name    = "${local.name_prefix}-subnet-group"
  security_group_name  = "${local.name_prefix}-sg"

  # Tag ordering matches the previous composition/elasticache module so the
  # rendered plan is byte-identical: common_tags first, Name next, var.tags
  # last (so caller-supplied tags win on conflicts like ManagedBy).
  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = "hyperswitch"
      "Component"   = "elasticache"
      "ManagedBy"   = "terraform"
      "Service"     = "hyperswitch-correlator"
    },
    var.tags,
  )
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "this" {
  name        = local.subnet_group_name
  subnet_ids  = var.subnet_ids
  description = "Event-Correlator ${title(var.environment)} Elasticache subnet group"

  tags = merge(local.common_tags, {
    Name = local.subnet_group_name
  })
}

# Security Group for ElastiCache
resource "aws_security_group" "this" {
  name                   = local.security_group_name
  description            = "Security group for event-correlator ${var.environment} ElastiCache"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(local.common_tags, {
    Name = local.security_group_name
  })
}

# ElastiCache Valkey Replication Group
resource "aws_elasticache_replication_group" "this" {
  replication_group_id = local.replication_group_id
  description          = "Event-Correlator ${title(var.environment)} Elasticache replication group"

  engine               = "valkey"
  engine_version       = var.engine_version
  parameter_group_name = "default.valkey${split(".", var.engine_version)[0]}"
  port                 = 6379

  node_type           = var.node_type
  num_cache_clusters  = var.num_cache_clusters
  cluster_mode        = "disabled"
  data_tiering_enabled = false

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.this.id]
  ip_discovery       = "ipv4"
  network_type       = "ipv4"

  automatic_failover_enabled = false
  multi_az_enabled           = false

  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = false

  maintenance_window         = var.maintenance_window
  snapshot_window            = var.snapshot_window
  snapshot_retention_limit   = var.snapshot_retention_limit
  auto_minor_version_upgrade = true
  apply_immediately          = var.apply_immediately

  tags = merge(local.common_tags, {
    Name = local.replication_group_id
  })

  lifecycle {
    ignore_changes = [
      engine_version, # Prevent unwanted version upgrades
    ]
  }
}
