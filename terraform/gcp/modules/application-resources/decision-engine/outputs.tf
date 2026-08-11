output "service_account_email" {
  description = "Email of decision-engine's Google service account"
  value       = module.workload_identity.service_account_email
}

output "k8s_service_account_name" {
  description = "Bound Kubernetes service account name"
  value       = module.workload_identity.k8s_service_account_name
}

output "bucket_name" {
  description = "Name of the dedicated bucket, if created"
  value       = var.create_bucket ? module.bucket[0].name : null
}
