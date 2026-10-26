module "elasticache" {
  count = var.create_locker_elasticache ? 1 : 0

  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/elasticache?ref=elasticache-v0.1.6"

  environment  = var.environment
  project_name = var.project_name
  region       = var.region

  vpc_id     = var.vpc_id
  subnet_ids = var.elasticache_config.subnet_ids

  create_elasticache_subnet_group = var.elasticache_config.create_elasticache_subnet_group
  elasticache_subnet_group_name   = var.elasticache_config.elasticache_subnet_group_name != null ? var.elasticache_config.elasticache_subnet_group_name : "${local.name_prefix}-cache-subnet-group"

  create_security_group       = var.elasticache_config.create_security_group
  security_group_name         = var.elasticache_config.security_group_name != null ? var.elasticache_config.security_group_name : "${local.name_prefix}-cache-sg"
  security_group_description  = var.elasticache_config.security_group_description != null ? var.elasticache_config.security_group_description : "Security group for locker cache"
  existing_security_group_ids = var.elasticache_config.existing_security_group_ids

  elasticache_replication_group_id = var.elasticache_config.elasticache_replication_group_id != null ? var.elasticache_config.elasticache_replication_group_id : "${local.name_prefix}-valkey"

  engine               = var.elasticache_config.engine
  engine_version       = var.elasticache_config.engine_version
  parameter_group_name = var.elasticache_config.parameter_group_name
  port                 = var.elasticache_config.port

  node_type               = var.elasticache_config.node_type
  cluster_mode            = var.elasticache_config.cluster_mode
  num_cache_clusters      = var.elasticache_config.num_cache_clusters
  num_node_groups         = var.elasticache_config.num_node_groups
  replicas_per_node_group = var.elasticache_config.replicas_per_node_group
  data_tiering_enabled    = var.elasticache_config.data_tiering_enabled

  automatic_failover_enabled = var.elasticache_config.automatic_failover_enabled
  multi_az_enabled           = var.elasticache_config.multi_az_enabled

  ip_discovery = var.elasticache_config.ip_discovery
  network_type = var.elasticache_config.network_type

  at_rest_encryption_enabled = var.elasticache_config.at_rest_encryption_enabled
  # Defaults to the locker's own KMS key when the module creates one, matching
  # the previous standalone locker-elasticache wiring (kms_key_id = locker key).
  kms_key_id                 = var.elasticache_config.kms_key_id != null ? var.elasticache_config.kms_key_id : (length(local.kms_key_arns) > 0 ? local.kms_key_arns[0] : null)
  transit_encryption_enabled = var.elasticache_config.transit_encryption_enabled

  maintenance_window         = var.elasticache_config.maintenance_window
  snapshot_window            = var.elasticache_config.snapshot_window
  snapshot_retention_limit   = var.elasticache_config.snapshot_retention_limit
  auto_minor_version_upgrade = var.elasticache_config.auto_minor_version_upgrade
  apply_immediately          = var.elasticache_config.apply_immediately

  create_global_replication_group = var.elasticache_config.create_global_replication_group
  global_replication_group_id     = var.elasticache_config.global_replication_group_id
  global_deletion_protection      = var.elasticache_config.global_deletion_protection
  is_secondary_region             = var.elasticache_config.is_secondary_region
  use_existing_as_global_primary  = var.elasticache_config.use_existing_as_global_primary
  source_replication_group_id     = var.elasticache_config.source_replication_group_id

  node_group_configuration = var.elasticache_config.node_group_configuration
  log_delivery             = var.elasticache_config.log_delivery

  tags = merge(local.common_tags, var.elasticache_config.tags)
}

# =========================================================================
# SECURITY GROUP RULES - LOCKER <-> ELASTICACHE
# =========================================================================
# Internal rules mirroring the locker <-> RDS pair in main.tf: the module
# owns the path between the locker instance and its cache. Only created when
# the elasticache module also creates the cache security group; with an
# externally supplied SG, manage the rules alongside that SG instead.
resource "aws_security_group_rule" "locker_egress_to_elasticache" {
  count = var.create_locker_elasticache && var.elasticache_config.create_security_group ? 1 : 0

  security_group_id        = local.locker_security_group_id
  type                     = "egress"
  from_port                = var.elasticache_config.port
  to_port                  = var.elasticache_config.port
  protocol                 = "tcp"
  source_security_group_id = module.elasticache[0].security_group_id
  description              = "Allow locker instance to connect to ElastiCache"
}

resource "aws_security_group_rule" "elasticache_ingress_from_locker" {
  count = var.create_locker_elasticache && var.elasticache_config.create_security_group ? 1 : 0

  security_group_id        = module.elasticache[0].security_group_id
  type                     = "ingress"
  from_port                = var.elasticache_config.port
  to_port                  = var.elasticache_config.port
  protocol                 = "tcp"
  source_security_group_id = local.locker_security_group_id
  description              = "Allow cache access from locker instance"
}
