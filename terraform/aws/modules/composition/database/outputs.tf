# RDS Cluster Outputs
output "cluster_id" {
  description = "RDS Cluster Identifier"
  value       = aws_rds_cluster.main.id
}

output "cluster_arn" {
  description = "Amazon Resource Name (ARN) of cluster"
  value       = aws_rds_cluster.main.arn
}

output "cluster_identifier" {
  description = "RDS Cluster Identifier"
  value       = aws_rds_cluster.main.cluster_identifier
}

output "cluster_resource_id" {
  description = "RDS Cluster Resource ID"
  value       = aws_rds_cluster.main.cluster_resource_id
}

output "cluster_members" {
  description = "List of RDS Instances that are a part of this cluster"
  value       = aws_rds_cluster.main.cluster_members
}

output "endpoint" {
  description = "DNS address of the RDS instance"
  value       = aws_rds_cluster.main.endpoint
}

output "reader_endpoint" {
  description = "Read-only endpoint for the Aurora cluster, automatically load-balanced across replicas"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "engine" {
  description = "Database engine"
  value       = aws_rds_cluster.main.engine
}

output "engine_version_actual" {
  description = "Running version of the database"
  value       = aws_rds_cluster.main.engine_version_actual
}

output "database_name" {
  description = "Database name"
  value       = aws_rds_cluster.main.database_name
}

output "port" {
  description = "Database port"
  value       = aws_rds_cluster.main.port
}

output "master_username" {
  description = "Master username for the database"
  value       = aws_rds_cluster.main.master_username
  sensitive   = true
}

output "master_user_secret" {
  description = "Block that specifies the master user secret. Only available when manage_master_user_password is set to true"
  value       = aws_rds_cluster.main.master_user_secret
  sensitive   = true
}

output "hosted_zone_id" {
  description = "Route53 Hosted Zone ID of the endpoint"
  value       = aws_rds_cluster.main.hosted_zone_id
}

output "availability_zones" {
  description = "Availability zones of the cluster"
  value       = aws_rds_cluster.main.availability_zones
}

output "backup_retention_period" {
  description = "Backup retention period"
  value       = aws_rds_cluster.main.backup_retention_period
}

output "preferred_backup_window" {
  description = "Daily time range during which the backups happen"
  value       = aws_rds_cluster.main.preferred_backup_window
}

output "preferred_maintenance_window" {
  description = "Maintenance window"
  value       = aws_rds_cluster.main.preferred_maintenance_window
}

output "storage_encrypted" {
  description = "Specifies whether the DB cluster is encrypted"
  value       = aws_rds_cluster.main.storage_encrypted
}

output "kms_key_id" {
  description = "KMS key identifier for encryption"
  value       = aws_rds_cluster.main.kms_key_id
}

output "replication_source_identifier" {
  description = "ARN of the source DB cluster or DB instance if this DB cluster is created as a Read Replica"
  value       = aws_rds_cluster.main.replication_source_identifier
}

output "ca_certificate_identifier" {
  description = "CA identifier of the CA certificate used for the DB instance's server certificate"
  value       = aws_rds_cluster.main.ca_certificate_identifier
}

output "ca_certificate_valid_till" {
  description = "Expiration date of the DB instance's server certificate"
  value       = aws_rds_cluster.main.ca_certificate_valid_till
}

# DB Subnet Group Outputs
output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = var.create_db_subnet_group ? aws_db_subnet_group.main[0].name : var.db_subnet_group_name
}

output "db_subnet_group_id" {
  description = "ID of the DB subnet group"
  value       = var.create_db_subnet_group ? aws_db_subnet_group.main[0].id : null
}

output "db_subnet_group_arn" {
  description = "ARN of the DB subnet group"
  value       = var.create_db_subnet_group ? aws_db_subnet_group.main[0].arn : null
}

# Security Group Outputs
output "security_group_id" {
  description = "ID of the security group created for RDS"
  value       = var.create_security_group ? aws_security_group.rds_sg[0].id : null
}

output "security_group_arn" {
  description = "ARN of the security group created for RDS"
  value       = var.create_security_group ? aws_security_group.rds_sg[0].arn : null
}

output "security_group_name" {
  description = "Name of the security group created for RDS"
  value       = var.create_security_group ? aws_security_group.rds_sg[0].name : null
}

# Cluster Instance Outputs
output "cluster_instance_ids" {
  description = "Map of cluster instance identifiers"
  value       = { for k, v in aws_rds_cluster_instance.instances : k => v.id }
}

output "cluster_instance_arns" {
  description = "Map of cluster instance ARNs"
  value       = { for k, v in aws_rds_cluster_instance.instances : k => v.arn }
}

output "cluster_instance_endpoints" {
  description = "Map of cluster instance endpoints"
  value       = { for k, v in aws_rds_cluster_instance.instances : k => v.endpoint }
}

output "cluster_instance_availability_zones" {
  description = "Map of cluster instance availability zones"
  value       = { for k, v in aws_rds_cluster_instance.instances : k => v.availability_zone }
}

output "cluster_instance_writer_status" {
  description = "Map indicating if each instance is a writer"
  value       = { for k, v in aws_rds_cluster_instance.instances : k => v.writer }
}

# Tags
output "tags_all" {
  description = "Map of tags assigned to the resource, including those inherited from the provider"
  value       = aws_rds_cluster.main.tags_all
}
