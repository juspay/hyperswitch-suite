# Replication Group Outputs
output "replication_group_id" {
  description = "ID of the ElastiCache Replication Group"
  value       = aws_elasticache_replication_group.main.id
}

output "replication_group_arn" {
  description = "ARN of the ElastiCache Replication Group"
  value       = aws_elasticache_replication_group.main.arn
}

output "replication_group_primary_endpoint_address" {
  description = "Address of the primary endpoint for the replication group"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "replication_group_reader_endpoint_address" {
  description = "Address of the reader endpoint for the replication group"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "replication_group_configuration_endpoint_address" {
  description = "Address of the configuration endpoint for the replication group"
  value       = aws_elasticache_replication_group.main.configuration_endpoint_address
}

output "replication_group_member_clusters" {
  description = "Identifiers of all member cache clusters"
  value       = aws_elasticache_replication_group.main.member_clusters
}

output "replication_group_port" {
  description = "Port number for the replication group"
  value       = aws_elasticache_replication_group.main.port
}

# Subnet Group Outputs
output "subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = var.create_elasticache_subnet_group ? aws_elasticache_subnet_group.elasticache_subnet_group[0].name : var.elasticache_subnet_group_name
}

output "subnet_group_id" {
  description = "ID of the ElastiCache subnet group"
  value       = var.create_elasticache_subnet_group ? aws_elasticache_subnet_group.elasticache_subnet_group[0].id : null
}

# Security Group Outputs
output "security_group_id" {
  description = "ID of the security group created for ElastiCache"
  value       = var.create_security_group ? aws_security_group.elasticache_sg[0].id : null
}

output "security_group_name" {
  description = "Name of the security group created for ElastiCache"
  value       = var.create_security_group ? aws_security_group.elasticache_sg[0].name : null
}

output "security_group_arn" {
  description = "ARN of the security group created for ElastiCache"
  value       = var.create_security_group ? aws_security_group.elasticache_sg[0].arn : null
}

output "all_security_group_ids" {
  description = "All security group IDs attached to ElastiCache"
  value       = aws_elasticache_replication_group.main.security_group_ids
}

# Connection Information
output "connection_info" {
  description = "Connection information for the ElastiCache cluster"
  value = {
    primary_endpoint = aws_elasticache_replication_group.main.primary_endpoint_address
    reader_endpoint  = aws_elasticache_replication_group.main.reader_endpoint_address
    port             = aws_elasticache_replication_group.main.port
    engine_version   = aws_elasticache_replication_group.main.engine_version_actual
  }
}

# Global Replication Group Outputs
output "global_replication_group_id" {
  description = "Global Replication Group Identifier"
  value       = var.create_global_replication_group && !local.is_secondary_cluster ? aws_elasticache_global_replication_group.main[0].id : null
}

output "global_replication_group_arn" {
  description = "ARN of the Global Replication Group"
  value       = var.create_global_replication_group && !local.is_secondary_cluster ? aws_elasticache_global_replication_group.main[0].arn : null
}

output "global_replication_group_name" {
  description = "Global Replication Group name"
  value       = var.create_global_replication_group && !local.is_secondary_cluster ? aws_elasticache_global_replication_group.main[0].global_replication_group_id : var.global_replication_group_id
}

output "is_primary_cluster" {
  description = "Whether this cluster is the primary cluster in the global replication group"
  value       = !local.is_secondary_cluster
}

output "is_secondary_cluster" {
  description = "Whether this cluster is a secondary/replica cluster in the global replication group"
  value       = local.is_secondary_cluster
}
