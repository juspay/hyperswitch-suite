# ============================================================================
# ElastiCache Redis Deployment - Dev Environment
# ============================================================================
# This configuration deploys AWS ElastiCache Redis Replication Group:
#   - Redis replication group with primary and replica nodes
#   - Multi-AZ deployment for high availability
#   - Automatic failover enabled
#   - ElastiCache subnet group across multiple AZs
#   - Security group for Redis access control
#   - Automated backups with configurable retention
#
# Access Method: Via VPC internal network only
# Security: Network isolation with security group rules
# High Availability: Multi-AZ with automatic failover
# Backups: Daily automated snapshots
# ============================================================================

provider "aws" {
  region = var.region
}

# ElastiCache Redis Module
module "elasticache" {
  source = "../../../../modules/composition/elasticache"

  # Environment Configuration
  environment  = var.environment
  project_name = var.project_name

  # Network Configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Replication Group Configuration
  elasticache_replication_group_id = var.elasticache_replication_group_id

  # Global Replication Configuration
  create_global_replication_group = var.create_global_replication_group
  global_replication_group_id     = var.global_replication_group_id
  global_deletion_protection      = var.global_deletion_protection
  is_secondary_region             = var.is_secondary_region
  use_existing_as_global_primary  = var.use_existing_as_global_primary
  source_replication_group_id     = var.source_replication_group_id

  # Engine Configuration
  engine               = var.engine
  engine_version       = var.engine_version
  parameter_group_name = var.parameter_group_name
  port                 = var.port

  # Node Configuration
  node_type          = var.node_type
  num_cache_clusters = var.num_cache_clusters

  # Cluster Mode
  cluster_mode         = var.cluster_mode
  data_tiering_enabled = var.data_tiering_enabled

  # High Availability
  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  # Network Configuration
  ip_discovery = var.ip_discovery
  network_type = var.network_type

  # Security
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  transit_encryption_mode    = var.transit_encryption_mode
  auth_token                 = var.auth_token

  # Maintenance & Backup
  maintenance_window         = var.maintenance_window
  snapshot_window            = var.snapshot_window
  snapshot_retention_limit   = var.snapshot_retention_limit
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  # Subnet Group
  create_elasticache_subnet_group = var.create_elasticache_subnet_group
  elasticache_subnet_group_name   = var.elasticache_subnet_group_name

  # Security Group
  create_security_group       = var.create_security_group
  security_group_name         = var.security_group_name
  security_group_description  = var.security_group_description
  existing_security_group_ids = var.existing_security_group_ids

  # Tags
  tags = var.tags
}
