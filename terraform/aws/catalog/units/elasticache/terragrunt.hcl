include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

# Disabled when the stack provides its own VPC via values (BYO-VPC / standalone)
dependency "vpc_network" {
  enabled     = try(values.vpc_id, null) == null
  config_path = "../vpc-network"

  mock_outputs = {
    elasticache_subnet_ids = ["mock-elasticache_subnet_ids"]
    vpc_id                 = "vpc-mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "elasticache_primary" {
  config_path = try(values.primary_elasticache_config_path, try("../../${values.primary_region}/elasticache", null))
  enabled     = try(values.is_passive, false)

  mock_outputs = {
    global_replication_group_id = "mock-global_replication_group_id"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/elasticache?ref=elasticache-v0.1.5"
}

inputs = {

  # Required Variables
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  # Network Configuration
  vpc_id     = try(values.vpc_id, null) != null ? values.vpc_id : dependency.vpc_network.outputs.vpc_id
  subnet_ids = try(values.elasticache_subnet_ids, null) != null ? values.elasticache_subnet_ids : dependency.vpc_network.outputs.elasticache_subnet_ids

  # Create new subnet group and security group
  create_elasticache_subnet_group = true

  create_security_group = true

  # Replication Group Configuration
  elasticache_replication_group_id = "${include.root.locals.environment.short}-${include.root.locals.project_name}-valkey"

  # Engine Configuration
  engine               = "valkey"
  engine_version       = try(values.engine_version, "8.2")
  parameter_group_name = "default.valkey8.cluster.on"
  port                 = 6379

  # Node Configuration
  node_type = try(values.cache_node_type, "cache.m6g.large")

  # Cluster Mode (enabled with 1 shard and 1 replica = 2 total nodes for 1 AZ)
  cluster_mode         = "enabled"
  num_node_groups      = 2
  data_tiering_enabled = false

  # High Availability
  automatic_failover_enabled = true
  multi_az_enabled           = true

  # Network Configuration
  ip_discovery = "ipv4"
  network_type = "ipv4"

  # Security
  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  # Maintenance & Backup
  maintenance_window         = "mon:04:00-mon:05:00"
  snapshot_window            = "23:30-00:30"
  snapshot_retention_limit   = 7
  auto_minor_version_upgrade = true
  apply_immediately          = true

  # Security Group Configuration
  existing_security_group_ids = []

  # Global Replication Configuration (secondary region)
  create_global_replication_group = !try(values.is_passive, false)
  global_replication_group_id     = try(values.is_passive, false) ? dependency.elasticache_primary.outputs.global_replication_group_id : try(values.global_replication_group_id, null)
  global_deletion_protection      = true
  is_secondary_region             = try(values.is_passive, false)
  use_existing_as_global_primary  = false
  source_replication_group_id     = null

  # Node Group Configuration (1 shard with 1 replica, 1 AZ deployment)
  node_group_configuration = [
    {
      node_group_id              = "0001"
      primary_availability_zone  = "${include.root.locals.region}a"
      replica_availability_zones = ["${include.root.locals.region}b"]
      replica_count              = 1
      slots                      = "0-8191"
    },
    {
      node_group_id              = "0002"
      primary_availability_zone  = "${include.root.locals.region}a"
      replica_availability_zones = ["${include.root.locals.region}b"]
      replica_count              = 1
      slots                      = "8192-16383"
    }
  ]

  # Tags
  tags = {
    Environment = include.root.locals.environment.short
    Project     = include.root.locals.project_name
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }

}
