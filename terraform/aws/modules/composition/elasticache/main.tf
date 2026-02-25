# ElastiCache Global Replication Group
resource "aws_elasticache_global_replication_group" "main" {
  count = var.create_global_replication_group && !local.is_secondary_cluster ? 1 : 0

  global_replication_group_id_suffix = replace(local.global_replication_group_id, "${local.name_prefix}-", "")
  primary_replication_group_id       = var.use_existing_as_global_primary ? var.source_replication_group_id : aws_elasticache_replication_group.main.id

  global_replication_group_description = "${title(var.project_name)} ${title(var.environment)} Global Redis"
  automatic_failover_enabled           = true
  cache_node_type                      = var.node_type
  engine_version                       = var.engine_version
  parameter_group_name                 = var.parameter_group_name

  lifecycle {
    ignore_changes = [
      primary_replication_group_id,
    ]
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "elasticache_subnet_group" {
  count = var.create_elasticache_subnet_group ? 1 : 0

  name        = local.elasticache_subnet_group_name
  subnet_ids  = var.subnet_ids
  description = "${title(var.project_name)} ${title(var.environment)} Elasticache subnet group"

  tags = merge(local.common_tags, {
    Name = local.elasticache_subnet_group_name
  })
}

# Security Group for ElastiCache
resource "aws_security_group" "elasticache_sg" {
  count = var.create_security_group ? 1 : 0

  name                   = local.security_group_name
  description            = local.security_group_description
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(local.common_tags, {
    Name = local.security_group_name
  })
}

# ElastiCache Redis Replication Group
resource "aws_elasticache_replication_group" "main" {
  # Required
  replication_group_id = local.elasticache_replication_group_id
  description          = "${title(var.project_name)} ${title(var.environment)} Elasticache replication group"

  # Engine Configuration
  engine               = local.is_secondary_cluster ? null : (var.snapshot_arn != null || var.snapshot_name != null ? null : var.engine)
  engine_version       = local.is_secondary_cluster ? null : (var.snapshot_arn != null || var.snapshot_name != null ? null : var.engine_version)
  parameter_group_name = local.is_secondary_cluster ? null : var.parameter_group_name
  port                 = local.is_secondary_cluster ? null : var.port
  node_type                   = local.is_secondary_cluster ? null : var.node_type
  num_cache_clusters          = local.is_secondary_cluster ? null : (var.num_node_groups == null ? var.num_cache_clusters : null)
  num_node_groups             = local.is_secondary_cluster ? null : var.num_node_groups
  replicas_per_node_group     = local.is_secondary_cluster ? null : var.replicas_per_node_group
  preferred_cache_cluster_azs = local.is_secondary_cluster ? null : var.preferred_cache_cluster_azs

  # Cluster Mode
  cluster_mode         = local.is_secondary_cluster ? null : var.cluster_mode
  data_tiering_enabled = local.is_secondary_cluster ? null : var.data_tiering_enabled

  # Network Configuration
  subnet_group_name  = var.create_elasticache_subnet_group ? aws_elasticache_subnet_group.elasticache_subnet_group[0].name : var.elasticache_subnet_group_name
  security_group_ids = concat(var.existing_security_group_ids, var.create_security_group ? [aws_security_group.elasticache_sg[0].id] : [])
  ip_discovery       = local.is_secondary_cluster ? null : var.ip_discovery
  network_type       = local.is_secondary_cluster ? null : var.network_type

  # High Availability
  automatic_failover_enabled = local.is_secondary_cluster ? null : var.automatic_failover_enabled
  multi_az_enabled           = local.is_secondary_cluster ? null : var.multi_az_enabled
  global_replication_group_id = local.is_secondary_cluster ? var.global_replication_group_id : null
  # Security
  at_rest_encryption_enabled = local.is_secondary_cluster ? null : var.at_rest_encryption_enabled
  transit_encryption_enabled = local.is_secondary_cluster ? null : var.transit_encryption_enabled
  transit_encryption_mode    = local.is_secondary_cluster ? null : var.transit_encryption_mode
  auth_token                 = local.is_secondary_cluster ? null : var.auth_token
  auth_token_update_strategy = local.is_secondary_cluster ? null : var.auth_token_update_strategy
  kms_key_id                 = local.is_secondary_cluster ? null : var.kms_key_id
  # Maintenance & Backup
  maintenance_window        = local.is_secondary_cluster ? null : var.maintenance_window
  snapshot_window           = local.is_secondary_cluster ? null : var.snapshot_window
  snapshot_retention_limit  = local.is_secondary_cluster ? null : var.snapshot_retention_limit
  snapshot_arns             = local.is_secondary_cluster ? null : (var.snapshot_arn != null ? [var.snapshot_arn] : var.snapshot_arns)
  snapshot_name             = local.is_secondary_cluster ? null : var.snapshot_name
  final_snapshot_identifier = local.is_secondary_cluster ? null : var.final_snapshot_identifier
  # Version Management
  auto_minor_version_upgrade = local.is_secondary_cluster ? null : var.auto_minor_version_upgrade
  apply_immediately          = local.is_secondary_cluster ? null : var.apply_immediately
  # Notifications
  notification_topic_arn = local.is_secondary_cluster ? null : var.notification_topic_arn
  # User Groups
  user_group_ids = local.is_secondary_cluster ? null : var.user_group_ids
  # Log Delivery Configuration
  dynamic "log_delivery_configuration" {
    for_each = local.is_secondary_cluster ? [] : var.log_delivery_configuration
    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = log_delivery_configuration.value.log_type
    }
  }
  # Node Group Configuration (for cluster mode)
  dynamic "node_group_configuration" {
    for_each = local.is_secondary_cluster ? [] : var.node_group_configuration
    content {
      node_group_id              = node_group_configuration.value.node_group_id
      primary_availability_zone  = node_group_configuration.value.primary_availability_zone
      primary_outpost_arn        = node_group_configuration.value.primary_outpost_arn
      replica_availability_zones = node_group_configuration.value.replica_availability_zones
      replica_count              = node_group_configuration.value.replica_count
      replica_outpost_arns       = node_group_configuration.value.replica_outpost_arns
      slots                      = node_group_configuration.value.slots
    }
  }
  tags = merge(local.common_tags, {
    Name = local.elasticache_replication_group_id
  })
  lifecycle {
    ignore_changes = [
      engine_version, # Prevent unwanted version upgrades
    ]
  }
}