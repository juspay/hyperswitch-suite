# RDS Cluster Outputs
output "cluster_id" {
  description = "RDS Cluster Identifier"
  value       = try(aws_rds_cluster.main[0].id, "")
}

output "cluster_arn" {
  description = "Amazon Resource Name (ARN) of cluster"
  value       = try(aws_rds_cluster.main[0].arn, "")
}

output "cluster_identifier" {
  description = "RDS Cluster Identifier"
  value       = try(aws_rds_cluster.main[0].cluster_identifier, "")
}

output "cluster_resource_id" {
  description = "RDS Cluster Resource ID"
  value       = try(aws_rds_cluster.main[0].cluster_resource_id, "")
}

output "cluster_members" {
  description = "List of RDS Instances that are a part of this cluster"
  value       = try(aws_rds_cluster.main[0].cluster_members, [])
}

output "endpoint" {
  description = "DNS address of the RDS instance"
  value       = try(aws_rds_cluster.main[0].endpoint, "")
}

output "reader_endpoint" {
  description = "Read-only endpoint for the Aurora cluster, automatically load-balanced across replicas"
  value       = try(aws_rds_cluster.main[0].reader_endpoint, "")
}

output "engine" {
  description = "Database engine"
  value       = try(aws_rds_cluster.main[0].engine, "")
}

output "engine_version_actual" {
  description = "Running version of the database"
  value       = try(aws_rds_cluster.main[0].engine_version_actual, "")
}

output "database_name" {
  description = "Database name"
  value       = try(aws_rds_cluster.main[0].database_name, "")
}

output "port" {
  description = "Database port"
  value       = try(aws_rds_cluster.main[0].port, null)
}

output "master_username" {
  description = "Master username for the database"
  value       = try(aws_rds_cluster.main[0].master_username, "")
  sensitive   = true
}

output "master_user_secret" {
  description = "Block that specifies the master user secret. Only available when manage_master_user_password is set to true"
  value       = try(aws_rds_cluster.main[0].master_user_secret, null)
  sensitive   = true
}

output "hosted_zone_id" {
  description = "Route53 Hosted Zone ID of the endpoint"
  value       = try(aws_rds_cluster.main[0].hosted_zone_id, "")
}

output "availability_zones" {
  description = "Availability zones of the cluster"
  value       = try(aws_rds_cluster.main[0].availability_zones, [])
}

output "backup_retention_period" {
  description = "Backup retention period"
  value       = try(aws_rds_cluster.main[0].backup_retention_period, null)
}

output "preferred_backup_window" {
  description = "Daily time range during which the backups happen"
  value       = try(aws_rds_cluster.main[0].preferred_backup_window, "")
}

output "preferred_maintenance_window" {
  description = "Maintenance window"
  value       = try(aws_rds_cluster.main[0].preferred_maintenance_window, "")
}

output "storage_encrypted" {
  description = "Specifies whether the DB cluster is encrypted"
  value       = try(aws_rds_cluster.main[0].storage_encrypted, false)
}

output "kms_key_id" {
  description = "KMS key identifier for encryption"
  value       = try(aws_rds_cluster.main[0].kms_key_id, "")
}

output "replication_source_identifier" {
  description = "ARN of the source DB cluster or DB instance if this DB cluster is created as a Read Replica"
  value       = try(aws_rds_cluster.main[0].replication_source_identifier, "")
}

output "ca_certificate_identifier" {
  description = "CA identifier of the CA certificate used for the DB instance's server certificate"
  value       = try(aws_rds_cluster.main[0].ca_certificate_identifier, "")
}

output "ca_certificate_valid_till" {
  description = "Expiration date of the DB instance's server certificate"
  value       = try(aws_rds_cluster.main[0].ca_certificate_valid_till, "")
}

# Global Cluster Outputs
output "global_cluster_id" {
  description = "Global Cluster Identifier"
  value       = var.create && var.create_global_cluster && !local.is_secondary_cluster ? try(aws_rds_global_cluster.main[0].id, "") : ""
}

output "global_cluster_arn" {
  description = "ARN of the Global Cluster"
  value       = var.create && var.create_global_cluster && !local.is_secondary_cluster ? try(aws_rds_global_cluster.main[0].arn, "") : ""
}

output "global_cluster_identifier" {
  description = "Global Cluster Identifier name"
  value       = var.create && var.create_global_cluster && !local.is_secondary_cluster ? try(aws_rds_global_cluster.main[0].global_cluster_identifier, "") : var.global_cluster_identifier
}

output "global_writer_endpoint" {
  description = "Global writer endpoint for the Aurora Global Database (use this for applications)"
  value       = var.create && var.create_global_cluster && !local.is_secondary_cluster ? try(aws_rds_global_cluster.main[0].global_cluster_resource_id, "") : ""
}

output "is_primary_cluster" {
  description = "Whether this cluster is the primary cluster in the global database"
  value       = !local.is_secondary_cluster
}

output "is_secondary_cluster" {
  description = "Whether this cluster is a secondary/replica cluster in the global database"
  value       = local.is_secondary_cluster
}

# DB Subnet Group Outputs
output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = var.create && var.create_db_subnet_group ? try(aws_db_subnet_group.main[0].name, "") : var.db_subnet_group_name
}

output "db_subnet_group_id" {
  description = "ID of the DB subnet group"
  value       = var.create && var.create_db_subnet_group ? try(aws_db_subnet_group.main[0].id, "") : ""
}

output "db_subnet_group_arn" {
  description = "ARN of the DB subnet group"
  value       = var.create && var.create_db_subnet_group ? try(aws_db_subnet_group.main[0].arn, "") : ""
}

# Security Group Outputs
output "security_group_id" {
  description = "ID of the security group created for RDS"
  value       = var.create && var.create_security_group ? try(aws_security_group.rds_sg[0].id, "") : ""
}

output "security_group_arn" {
  description = "ARN of the security group created for RDS"
  value       = var.create && var.create_security_group ? try(aws_security_group.rds_sg[0].arn, "") : ""
}

output "security_group_name" {
  description = "Name of the security group created for RDS"
  value       = var.create && var.create_security_group ? try(aws_security_group.rds_sg[0].name, "") : ""
}

# Cluster Instance Outputs
output "cluster_instance_ids" {
  description = "Map of cluster instance identifiers"
  value       = var.create ? { for k, v in aws_rds_cluster_instance.instances : k => v.id } : {}
}

output "cluster_instance_arns" {
  description = "Map of cluster instance ARNs"
  value       = var.create ? { for k, v in aws_rds_cluster_instance.instances : k => v.arn } : {}
}

output "cluster_instance_endpoints" {
  description = "Map of cluster instance endpoints"
  value       = var.create ? { for k, v in aws_rds_cluster_instance.instances : k => v.endpoint } : {}
}

output "cluster_instance_availability_zones" {
  description = "Map of cluster instance availability zones"
  value       = var.create ? { for k, v in aws_rds_cluster_instance.instances : k => v.availability_zone } : {}
}

output "cluster_instance_writer_status" {
  description = "Map indicating if each instance is a writer"
  value       = var.create ? { for k, v in aws_rds_cluster_instance.instances : k => v.writer } : {}
}

# Tags
output "tags_all" {
  description = "Map of tags assigned to the resource, including those inherited from the provider"
  value       = try(aws_rds_cluster.main[0].tags_all, {})
}
