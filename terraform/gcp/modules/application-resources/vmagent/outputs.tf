output "service_account_email" {
  description = "Email of vmagent's Google service account - use as the iam.gke.io/gcp-service-account annotation on the vmagent Kubernetes service account"
  value       = module.workload_identity.gcp_service_account_email
}

output "k8s_service_account_name" {
  description = "Bound Kubernetes service account name"
  value       = module.workload_identity.k8s_service_account_name
}
