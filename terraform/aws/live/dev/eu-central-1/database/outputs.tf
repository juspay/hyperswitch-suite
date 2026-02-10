# ============================================================================
# RDS Cluster Outputs
# ============================================================================

output "cluster_id" {
  description = "RDS Cluster Identifier"
  value       = module.database.cluster_id
}

output "cluster_arn" {
  description = "Amazon Resource Name (ARN) of cluster"
  value       = module.database.cluster_arn
}

output "cluster_identifier" {
  description = "RDS Cluster Identifier"
  value       = module.database.cluster_identifier
}

output "cluster_resource_id" {
  description = "RDS Cluster Resource ID"
  value       = module.database.cluster_resource_id
}

output "cluster_members" {
  description = "List of RDS Instances that are part of this cluster"
  value       = module.database.cluster_members
}

output "endpoint" {
  description = "Writer endpoint for the cluster"
  value       = module.database.endpoint
}

output "reader_endpoint" {
  description = "Read-only endpoint for the Aurora cluster"
  value       = module.database.reader_endpoint
}

output "engine" {
  description = "Database engine"
  value       = module.database.engine
}

output "engine_version_actual" {
  description = "Running version of the database"
  value       = module.database.engine_version_actual
}

output "database_name" {
  description = "Database name"
  value       = module.database.database_name
}

output "port" {
  description = "Database port"
  value       = module.database.port
}

output "master_username" {
  description = "Master username for the database"
  value       = module.database.master_username
  sensitive   = true
}

# ============================================================================
# Cluster Instance Outputs
# ============================================================================

output "cluster_instance_ids" {
  description = "Map of cluster instance identifiers"
  value       = module.database.cluster_instance_ids
}

output "cluster_instance_arns" {
  description = "Map of cluster instance ARNs"
  value       = module.database.cluster_instance_arns
}

output "cluster_instance_endpoints" {
  description = "Map of cluster instance endpoints"
  value       = module.database.cluster_instance_endpoints
}

output "cluster_instance_availability_zones" {
  description = "Map of cluster instance availability zones"
  value       = module.database.cluster_instance_availability_zones
}

output "cluster_instance_writer_status" {
  description = "Map indicating if each instance is a writer"
  value       = module.database.cluster_instance_writer_status
}

# ============================================================================
# Network Outputs
# ============================================================================

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = module.database.db_subnet_group_name
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.database.security_group_id
}

# ============================================================================
# Security Outputs
# ============================================================================

output "storage_encrypted" {
  description = "Whether the DB cluster is encrypted"
  value       = module.database.storage_encrypted
}

output "kms_key_id" {
  description = "KMS key identifier for encryption"
  value       = module.database.kms_key_id
}
