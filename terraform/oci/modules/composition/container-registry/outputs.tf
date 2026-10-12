# Output contract. Two AWS outputs have no counterpart here and are documented
# rather than faked:
#   repository_policies - the grant is compartment-level, not per-repository, so
#     nothing per-repository to emit; access_policy_statements covers it.
#   lifecycle_policies  - no retention mechanism exists in the provider, so an
#     empty map would imply the feature is merely unconfigured; it is absent.

output "repository_ocids" {
  description = "Map of repository key to OCID. Closest counterpart to AWS's repository_arns - the OCID plays the ARN role."
  value       = { for k, v in oci_artifacts_container_repository.this : k => v.id }
}

output "repository_names" {
  description = "Map of repository key to OCIR display name (the namespace-unique path, including var.repository_name_prefix)"
  value       = { for k, v in oci_artifacts_container_repository.this : k => v.display_name }
}

output "repository_urls" {
  description = "Map of repository key to full pull path: <ocir-endpoint>/<tenancy-namespace>/<repository>. Note the compartment does NOT appear here (check sheet feature 2)."
  value       = { for k, v in oci_artifacts_container_repository.this : k => "${local.registry_url}/${v.display_name}" }
}

output "registry_namespaces" {
  description = "Map of repository key to OCIR namespace. Counterpart of AWS's registry_ids - OCIR has no numeric registry id, the tenancy namespace fills that role and is identical for every repository."
  value       = { for k, v in oci_artifacts_container_repository.this : k => v.namespace }
}

output "registry_url" {
  description = "The registry root: <ocir-endpoint>/<tenancy-namespace>"
  value       = local.registry_url
}

output "namespace" {
  description = "The tenancy Object Storage / OCIR namespace used to build every URL above"
  value       = local.namespace
}

# Image-pull bootstrap surface.
# These two values are what cluster bootstrap needs to build the `docker-registry`
# Secret OKE requires for private pulls (see main.tf). Both are non-secret. The
# third value that Secret needs - the Auth Token itself - is a long-lived
# credential this module deliberately does not create, read or output.
output "image_pull_secret_docker_server" {
  description = "The --docker-server value for the OKE imagePullSecret. Non-secret."
  value       = local.ocir_endpoint
}

output "image_pull_username_prefix" {
  description = "The '<tenancy-namespace>/' prefix of the imagePullSecret --docker-username; the bootstrap step appends the OCI username. Non-secret. The Auth Token that completes the credential is NOT produced by this module - see main.tf."
  value       = "${local.namespace}/"
}

# Access-policy surface (the repository_policy substitute)
output "access_policy_id" {
  description = "OCID of the compartment-level registry access policy, or null when no push/pull subject was supplied"
  value       = try(oci_identity_policy.registry_access[0].id, null)
}

output "access_policy_statements" {
  description = "The rendered IAM statements granting registry access. Replaces AWS's per-repository repository_policies output - one compartment-scoped list instead of ~130 attached documents."
  value       = local.registry_statements
}

output "region" {
  description = "OCI region identifier, passed through (an OCIR repository exposes no region attribute to read back)"
  value       = var.region
}
