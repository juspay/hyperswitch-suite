output "replication_group_id" {
  description = "ID of the Valkey replication group"
  value       = aws_elasticache_replication_group.this.id
}

output "replication_group_arn" {
  description = "ARN of the Valkey replication group"
  value       = aws_elasticache_replication_group.this.arn
}

output "replication_group_primary_endpoint_address" {
  description = "Primary endpoint address (used by the correlator service for Redis HOST)"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "replication_group_reader_endpoint_address" {
  description = "Reader endpoint address of the replication group"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "replication_group_configuration_endpoint_address" {
  description = "Configuration endpoint address (cluster mode only; null when cluster_mode is disabled)"
  value       = aws_elasticache_replication_group.this.configuration_endpoint_address
}

output "replication_group_member_clusters" {
  description = "List of member cluster IDs in the replication group"
  value       = aws_elasticache_replication_group.this.member_clusters
}

output "replication_group_port" {
  description = "Port the replication group listens on"
  value       = aws_elasticache_replication_group.this.port
}

output "security_group_id" {
  description = "ID of the security group attached to the Valkey cluster (used by security-rules module)"
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "ARN of the security group attached to the Valkey cluster"
  value       = aws_security_group.this.arn
}

output "security_group_name" {
  description = "Name of the security group attached to the Valkey cluster"
  value       = aws_security_group.this.name
}

output "subnet_group_id" {
  description = "ID of the ElastiCache subnet group"
  value       = aws_elasticache_subnet_group.this.id
}

output "subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = aws_elasticache_subnet_group.this.name
}

output "connection_info" {
  description = "Convenience map with the connection details a client needs"
  value = {
    primary_endpoint = aws_elasticache_replication_group.this.primary_endpoint_address
    reader_endpoint  = aws_elasticache_replication_group.this.reader_endpoint_address
    port             = aws_elasticache_replication_group.this.port
    engine_version   = aws_elasticache_replication_group.this.engine_version_actual
  }
}

output "all_security_group_ids" {
  description = "All security group IDs attached to the replication group"
  value       = aws_elasticache_replication_group.this.security_group_ids
}

output "is_primary_cluster" {
  description = "Whether this cluster is the primary cluster in a global replication group (always true — global replication is not supported here)"
  value       = true
}

output "is_secondary_cluster" {
  description = "Whether this cluster is a secondary cluster in a global replication group (always false — global replication is not supported here)"
  value       = false
}
