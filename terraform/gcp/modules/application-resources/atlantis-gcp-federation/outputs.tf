output "workload_identity_pool_name" {
  description = "Fully qualified workload identity pool name (projects/.../locations/global/workloadIdentityPools/atlantis-aws-pool)"
  value       = google_iam_workload_identity_pool.atlantis.name
}

output "workload_identity_pool_provider_name" {
  description = "Fully qualified provider name - the resource passed to `gcloud iam workload-identity-pools create-cred-config`"
  value       = google_iam_workload_identity_pool_provider.atlantis_aws.name
}
