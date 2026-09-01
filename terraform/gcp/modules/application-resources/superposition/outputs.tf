output "service_account_email" {
  description = "Email of Superposition's Google service account"
  value       = module.workload_identity.service_account_email
}

output "k8s_service_account_name" {
  description = "Bound Kubernetes service account name"
  value       = module.workload_identity.k8s_service_account_name
}

output "database_instance_connection_name" {
  description = "Cloud SQL Auth Proxy connection name for Superposition's database, if created"
  value       = var.create_database ? module.database[0].instance_connection_name : null
}

output "database_name" {
  description = "Name of the Superposition database, if created"
  value       = var.create_database ? module.database[0].database_name : null
}
