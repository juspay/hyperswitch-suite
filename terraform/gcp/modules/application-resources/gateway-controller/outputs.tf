output "ssl_policy_id" {
  description = "ID of the SSL policy, if created"
  value       = var.create_ssl_policy ? google_compute_ssl_policy.gateway[0].id : null
}

output "service_account_email" {
  description = "Email of the controller-adjacent service account, if created"
  value       = var.create_service_account ? module.workload_identity[0].service_account_email : null
}
