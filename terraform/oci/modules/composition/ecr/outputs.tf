output "repository_ids" {
  value = { for k, v in oci_artifacts_container_repository.repositories : k => v.id }
}

output "repository_urls" {
  description = "Push/pull path: <region-key>.ocir.io/<tenancy-namespace>/<repo-name>"
  value       = { for k, v in oci_artifacts_container_repository.repositories : k => v.display_name }
}
