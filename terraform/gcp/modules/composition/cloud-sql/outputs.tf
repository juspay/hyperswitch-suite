output "instance_name" {
  description = "Name of the primary Cloud SQL instance"
  value       = module.cloud_sql.instance_name
}

output "instance_connection_name" {
  description = "Connection name for the Cloud SQL Auth Proxy (project:region:instance)"
  value       = module.cloud_sql.instance_connection_name
}

output "instance_self_link" {
  description = "Self-link of the primary instance"
  value       = module.cloud_sql.instance_self_link
}

output "private_ip_address" {
  description = "Private IP address of the primary instance"
  value       = module.cloud_sql.private_ip_address
}

output "database_name" {
  description = "Name of the default database"
  value       = var.database_name
}

output "master_username" {
  description = "Name of the default database user"
  value       = var.master_username
}

output "generated_user_password" {
  description = "Auto-generated password for the default user, if master_password was not set"
  value       = module.cloud_sql.generated_user_password
  sensitive   = true
}

output "read_replica_instance_names" {
  description = "Names of the created read replicas"
  value       = module.cloud_sql.read_replica_instance_names
}

output "kms_key_name" {
  description = "Self-link of the KMS key used for disk encryption, if any"
  value       = local.kms_key_name
}
