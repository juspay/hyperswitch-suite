# ============================================================================
# Environment Configuration
# ============================================================================
environment  = "dev"
project_name = "hyperswitch"
region       = "eu-central-1"

# ============================================================================
# Network Configuration
# ============================================================================
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"
subnet_ids = [
  "subnet-xxxxxxxxxxxxxxxxx",
  "subnet-yyyyyyyyyyyyyyyyy",
  "subnet-zzzzzzzzzzzzzzzzz"
]

# ============================================================================
# ElastiCache Replication Group Configuration
# ============================================================================
elasticache_replication_group_id = "my-redis-cluster"

# Engine Configuration
engine               = "redis"
engine_version       = "7.0"
parameter_group_name = "default.redis7"
port                 = 6379

# Node Configuration
node_type          = "cache.t3.small"
num_cache_clusters = 2

# Cluster Mode
cluster_mode         = "enabled"
data_tiering_enabled = false

# High Availability
automatic_failover_enabled = true
multi_az_enabled           = true

# Network Configuration
ip_discovery = "ipv4"
network_type = "ipv4"

# Security
at_rest_encryption_enabled = false
transit_encryption_enabled = false

# Maintenance & Backup
maintenance_window       = "sun:05:00-sun:06:00"
snapshot_window          = "03:00-05:00"
snapshot_retention_limit = 7
auto_minor_version_upgrade = true
apply_immediately          = false

# Subnet Group Configuration
create_elasticache_subnet_group = true
elasticache_subnet_group_name   = "my-redis-subnet-group"

# Security Group Configuration
create_security_group       = true
security_group_description  = "Security group for Hyperswitch Dev ElastiCache"
existing_security_group_ids = []

# Tags
tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Service     = "ElastiCache"
  Project     = "Hyperswitch"
}
