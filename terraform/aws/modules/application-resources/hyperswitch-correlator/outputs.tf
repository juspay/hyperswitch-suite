output "replication_group_id" {
  description = "ID of the Valkey replication group"
  value       = module.valkey.replication_group_id
}

output "replication_group_primary_endpoint_address" {
  description = "Primary endpoint address (used by the correlator service for Redis HOST)"
  value       = module.valkey.replication_group_primary_endpoint_address
}

output "security_group_id" {
  description = "ID of the security group attached to the Valkey cluster (used by security-rules module)"
  value       = module.valkey.security_group_id
}

output "subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = module.valkey.subnet_group_name
}
