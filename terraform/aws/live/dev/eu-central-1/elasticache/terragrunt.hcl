include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../..//modules/composition/elasticache"
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    vpc_id                 = "vpc-XXXXXXXXXXXXXXXXX"
    elasticache_subnet_ids = ["subnet-XXXXXXXXXXXXXXXXX", "subnet-YYYYYYYYYYYYYYYYY", "subnet-ZZZZZZZZZZZZZZZZZ"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name

  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.elasticache_subnet_ids

  elasticache_replication_group_id = "my-redis-cluster"

  create_global_replication_group = false
  global_replication_group_id     = "hyperswitch-redis-global"
  global_deletion_protection      = true
  is_secondary_region             = false
  use_existing_as_global_primary  = false
  source_replication_group_id     = null

  engine               = "redis"
  engine_version       = "7.0"
  parameter_group_name = "default.redis7.cluster.on"
  port                 = 6379

  node_type          = "cache.r6g.large"
  num_cache_clusters = 2

  cluster_mode            = "enabled"
  data_tiering_enabled    = false
  num_node_groups         = 1
  replicas_per_node_group = 1

  automatic_failover_enabled = true
  multi_az_enabled           = true

  ip_discovery = "ipv4"
  network_type = "ipv4"

  at_rest_encryption_enabled = false
  transit_encryption_enabled = false
  transit_encryption_mode    = null
  auth_token                 = null

  maintenance_window         = "sun:05:00-sun:06:00"
  snapshot_window            = "03:00-05:00"
  snapshot_retention_limit   = 7
  auto_minor_version_upgrade = false
  apply_immediately          = false

  create_elasticache_subnet_group = true
  elasticache_subnet_group_name   = "my-redis-subnet-group"

  create_security_group       = true
  security_group_name         = null
  security_group_description  = "Security group for Hyperswitch Dev ElastiCache"
  existing_security_group_ids = []

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Service     = "ElastiCache"
    Project     = "Hyperswitch"
  }
}
