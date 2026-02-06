# ============================================================================
# ElastiCache Replication Group Outputs
# ============================================================================

output "replication_group_id" {
  description = "ID of the ElastiCache Replication Group"
  value       = module.elasticache.replication_group_id
}

output "replication_group_arn" {
  description = "ARN of the ElastiCache Replication Group"
  value       = module.elasticache.replication_group_arn
}

output "replication_group_primary_endpoint_address" {
  description = "Primary endpoint address for the replication group"
  value       = module.elasticache.replication_group_primary_endpoint_address
}

output "replication_group_reader_endpoint_address" {
  description = "Reader endpoint address for the replication group"
  value       = module.elasticache.replication_group_reader_endpoint_address
}

output "replication_group_configuration_endpoint_address" {
  description = "Configuration endpoint address for cluster mode enabled"
  value       = module.elasticache.replication_group_configuration_endpoint_address
}

output "replication_group_member_clusters" {
  description = "List of member clusters in the replication group"
  value       = module.elasticache.replication_group_member_clusters
}

output "replication_group_cluster_enabled" {
  description = "Whether cluster mode is enabled"
  value       = module.elasticache.replication_group_cluster_enabled
}

output "replication_group_engine_version_actual" {
  description = "Actual engine version after upgrade"
  value       = module.elasticache.replication_group_engine_version_actual
}

# ============================================================================
# ElastiCache Subnet Group Outputs
# ============================================================================

output "elasticache_subnet_group_id" {
  description = "ID of the ElastiCache subnet group"
  value       = module.elasticache.elasticache_subnet_group_id
}

output "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = module.elasticache.elasticache_subnet_group_name
}

output "elasticache_subnet_group_arn" {
  description = "ARN of the ElastiCache subnet group"
  value       = module.elasticache.elasticache_subnet_group_arn
}

output "elasticache_subnet_group_description" {
  description = "Description of the ElastiCache subnet group"
  value       = module.elasticache.elasticache_subnet_group_description
}

output "elasticache_subnet_group_subnet_ids" {
  description = "Subnet IDs in the ElastiCache subnet group"
  value       = module.elasticache.elasticache_subnet_group_subnet_ids
}

output "elasticache_subnet_group_vpc_id" {
  description = "VPC ID of the ElastiCache subnet group"
  value       = module.elasticache.elasticache_subnet_group_vpc_id
}

# ============================================================================
# Security Group Outputs
# ============================================================================

output "security_group_id" {
  description = "ID of the security group"
  value       = module.elasticache.security_group_id
}

output "security_group_name" {
  description = "Name of the security group"
  value       = module.elasticache.security_group_name
}

output "security_group_arn" {
  description = "ARN of the security group"
  value       = module.elasticache.security_group_arn
}

output "security_group_vpc_id" {
  description = "VPC ID of the security group"
  value       = module.elasticache.security_group_vpc_id
}

# ============================================================================
# Connection Information
# ============================================================================

output "connection_info" {
  description = "Connection information for the Redis cluster"
  value       = module.elasticache.connection_info
}
