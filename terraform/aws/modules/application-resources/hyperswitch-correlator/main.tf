# Composition module — hyperswitch-correlator Valkey
#
# Wraps the elasticache module with all correlator-specific defaults so that
# the two production live-layer terragrunt.hcl files (eu-west-1 and us-east-1)
# only need to supply the region-specific network inputs. Any future change to
# the Valkey configuration (version bump, node type, backup policy, etc.) only
# needs to happen here.

module "valkey" {
  source = "../../composition/elasticache"

  # Identity
  environment  = var.environment
  project_name = "event-correlator"
  region       = var.region

  # Network
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Subnet group and security group — always created by this module
  create_elasticache_subnet_group = true
  create_security_group           = true
  existing_security_group_ids     = []

  # Replication group identity
  elasticache_replication_group_id = "hyperswitch-correlator-valkey"

  # Engine
  engine               = "valkey"
  engine_version       = var.engine_version
  parameter_group_name = "default.valkey${split(".", var.engine_version)[0]}"
  port                 = 6379

  # Node — standalone single-node (1 primary, no replicas)
  node_type            = var.node_type
  cluster_mode         = "disabled"
  num_cache_clusters   = var.num_cache_clusters
  data_tiering_enabled = false

  # HA — disabled (standalone instance, no cross-AZ failover needed)
  automatic_failover_enabled = false
  multi_az_enabled           = false

  # Network stack
  ip_discovery = "ipv4"
  network_type = "ipv4"

  # Encryption
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = false

  # Maintenance & backups
  maintenance_window         = var.maintenance_window
  snapshot_window            = var.snapshot_window
  snapshot_retention_limit   = var.snapshot_retention_limit
  auto_minor_version_upgrade = true
  apply_immediately          = var.apply_immediately

  # Global replication — disabled (independent instance per region)
  create_global_replication_group = false
  global_replication_group_id     = "hyperswitch-correlator-valkey-global"
  global_deletion_protection      = true
  is_secondary_region             = false
  use_existing_as_global_primary  = false
  source_replication_group_id     = null

  tags = merge(
    {
      Service   = "hyperswitch-correlator"
      ManagedBy = "terraform-IaC"
    },
    var.tags,
  )
}
