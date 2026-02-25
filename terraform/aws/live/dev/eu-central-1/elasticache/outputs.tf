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

output "replication_group_port" {
  description = "Port number for the replication group"
  value       = module.elasticache.replication_group_port
}

# ============================================================================
# ElastiCache Subnet Group Outputs
# ============================================================================

output "subnet_group_id" {
  description = "ID of the ElastiCache subnet group"
  value       = module.elasticache.subnet_group_id
}

output "subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = module.elasticache.subnet_group_name
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

output "all_security_group_ids" {
  description = "All security group IDs attached to ElastiCache"
  value       = module.elasticache.all_security_group_ids
}

# ============================================================================
# Connection Information
# ============================================================================

output "connection_info" {
  description = "Connection information for the Redis cluster"
  value       = module.elasticache.connection_info
}


# ============================================================================
# Global Replication Group Outputs
# ============================================================================

output "global_replication_group_id" {
  description = "Global Replication Group Identifier (AWS-generated ID)"
  value       = module.elasticache.global_replication_group_id
}

output "global_replication_group_name" {
  description = "Global Replication Group name (AWS-generated name)"
  value       = module.elasticache.global_replication_group_name
}

output "global_replication_group_suffix" {
  description = "User-specified suffix for the Global Replication Group (may differ from actual AWS-generated ID)"
  value       = module.elasticache.global_replication_group_suffix
}

output "is_primary_cluster" {
  description = "Whether this cluster is the primary cluster in the global replication group"
  value       = module.elasticache.is_primary_cluster
}

output "is_secondary_cluster" {
  description = "Whether this cluster is a secondary/replica cluster in the global replication group"
  value       = module.elasticache.is_secondary_cluster
}