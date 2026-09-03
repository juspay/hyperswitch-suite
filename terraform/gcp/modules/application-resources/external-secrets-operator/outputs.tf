output "service_account_email" {
  description = "Email of the operator's Google service account - the value a SecretStore's workloadIdentity/serviceAccountRef ultimately resolves to"
  value       = module.workload_identity.gcp_service_account_email
}

output "service_account_name" {
  description = "Fully qualified name of the operator's Google service account"
  value       = module.workload_identity.gcp_service_account_name
}

output "k8s_service_account_name" {
  description = "Bound Kubernetes service account name"
  value       = module.workload_identity.k8s_service_account_name
}

output "k8s_service_account_namespace" {
  description = "Namespace of the bound Kubernetes service account"
  value       = module.workload_identity.k8s_service_account_namespace
}

output "granted_project_roles" {
  description = "Project-level IAM roles actually granted to the operator's service account"
  value       = local.project_roles
}

output "granted_secret_ids" {
  description = "Secret Manager secret IDs granted per-secret accessor access"
  value       = var.secret_ids
}
