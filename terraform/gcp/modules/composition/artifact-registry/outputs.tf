output "repository_ids" {
  description = "Map of repository key to its fully qualified ID"
  value       = { for k, v in google_artifact_registry_repository.this : k => v.id }
}

output "repository_names" {
  description = "Map of repository key to its repository_id"
  value       = { for k, v in google_artifact_registry_repository.this : k => v.repository_id }
}

output "repository_urls" {
  description = "Map of repository key to its pull/push URL (<location>-docker.pkg.dev/<project>/<repo>)"
  value = {
    for k, v in google_artifact_registry_repository.this :
    k => "${var.location}-docker.pkg.dev/${var.project_id}/${v.repository_id}"
  }
}
