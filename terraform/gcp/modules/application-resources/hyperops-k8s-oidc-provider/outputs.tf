output "workload_identity_pool_provider_name" {
  description = "Fully qualified provider name, used as the credential config's audience"
  value       = google_iam_workload_identity_pool_provider.hyperops_k8s.name
}
