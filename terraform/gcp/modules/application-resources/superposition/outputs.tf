output "service_account_email" {
  description = "Email of Superposition's Google service account"
  value       = module.workload_identity.gcp_service_account_email
}

output "k8s_service_account_name" {
  description = "Bound Kubernetes service account name"
  value       = module.workload_identity.k8s_service_account_name
}

output "database_host" {
  description = "Private IP of the AlloyDB primary instance - use as Superposition's database host, if created"
  value       = var.create_database ? module.database[0].primary_instance_ip : null
}

output "database_cluster_id" {
  description = "ID of Superposition's AlloyDB cluster, if created"
  value       = var.create_database ? module.database[0].cluster_id : null
}

output "database_master_username" {
  description = "Bootstrap admin username on Superposition's AlloyDB cluster, if created"
  value       = var.create_database ? module.database[0].master_username : null
}

output "database_password_secret_id" {
  description = "Secret Manager secret ID holding the generated master password, if database_config.secret_manager.create was set"
  value       = var.create_database ? module.database[0].secret_manager_secret_id : null
  sensitive   = true
}
