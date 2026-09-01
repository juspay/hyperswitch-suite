output "cluster_id" {
  description = "AlloyDB cluster ID"
  value       = local.cluster_id
}

output "cluster_name" {
  description = "Fully-qualified cluster resource name"
  value       = module.alloydb.cluster_name
}

output "primary_instance_id" {
  description = "ID of the primary instance"
  value       = module.alloydb.primary_instance_id
}

output "primary_instance_ip" {
  description = "Private IP address of the primary instance - use this as the app's DB host"
  value       = module.alloydb.primary_instance_ip
}

output "read_instance_ids" {
  description = "IDs of the read pool instances, if any"
  value       = module.alloydb.read_instance_ids
}

output "read_instance_ips" {
  description = "Private IP addresses of the read pool instances, if any"
  value       = module.alloydb.read_instance_ips
}

output "master_username" {
  description = "Name of the bootstrap admin user"
  value       = var.master_username
}

output "generated_user_password" {
  description = "The master password in effect (module-generated if master_password was left unset)"
  value       = local.master_password
  sensitive   = true
}

output "kms_key_name" {
  description = "Self-link of the KMS key used for cluster encryption, if any"
  value       = local.kms_key_name
}

output "secret_manager_secret_id" {
  description = "Secret ID of the Secret Manager secret holding the generated master password, if secret_manager.create was set"
  value       = local.secret_manager_create ? google_secret_manager_secret.master_password[0].secret_id : null
  sensitive   = true
}

output "secret_manager_secret_name" {
  description = "Fully-qualified name (projects/.../secrets/...) of the Secret Manager secret, if created"
  value       = local.secret_manager_create ? google_secret_manager_secret.master_password[0].name : null
  sensitive   = true
}
