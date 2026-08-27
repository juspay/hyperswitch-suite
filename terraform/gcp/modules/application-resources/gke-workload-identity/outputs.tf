output "service_account_email" {
  description = "Email of the created Google service account"
  value       = module.workload_identity.gcp_service_account_email
}

output "service_account_name" {
  description = "Fully qualified name of the Google service account"
  value       = module.workload_identity.gcp_service_account_name
}

output "k8s_service_account_name" {
  description = "Name of the bound Kubernetes service account"
  value       = module.workload_identity.k8s_service_account_name
}

output "k8s_service_account_namespace" {
  description = "Namespace of the bound Kubernetes service account"
  value       = module.workload_identity.k8s_service_account_namespace
}

output "bucket_name" {
  description = "Name of the companion bucket, if created"
  value       = var.create_bucket ? module.bucket[0].name : null
}
