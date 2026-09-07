output "workload_identity_pool_name" {
  description = "Fully qualified workload identity pool name (projects/.../locations/global/workloadIdentityPools/infraswitch-aws-pool)"
  value       = google_iam_workload_identity_pool.infraswitch.name
}

output "workload_identity_pool_provider_name" {
  description = "Fully qualified provider name - the resource passed to `gcloud iam workload-identity-pools create-cred-config`"
  value       = google_iam_workload_identity_pool_provider.infraswitch_aws.name
}
