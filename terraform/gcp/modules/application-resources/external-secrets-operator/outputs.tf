output "service_account_email" {
  description = "Email of the operator's Google service account"
  value       = module.workload_identity.service_account_email
}

output "k8s_service_account_name" {
  description = "Bound Kubernetes service account name"
  value       = module.workload_identity.k8s_service_account_name
}
