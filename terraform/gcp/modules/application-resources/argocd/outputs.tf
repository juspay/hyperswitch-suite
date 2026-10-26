output "service_account_email" {
  description = "Email of ArgoCD's Google service account"
  value       = module.workload_identity.gcp_service_account_email
}

output "k8s_service_account_name" {
  description = "Bound Kubernetes service account name"
  value       = module.workload_identity.k8s_service_account_name
}
