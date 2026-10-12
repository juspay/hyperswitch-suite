# Output contract

output "policy_statements" {
  description = <<-EOT
    This module's contribution to the ONE shared, environment-scoped
    `oci_identity_policy` owned by the `oke-workload-identity` unit. Rendered,
    normalised and sorted.

    THIS MODULE CREATES NO POLICY OBJECT (identity-model.md section 3.7 - `name`
    is tenancy-unique and non-updatable, and per-app objects exceed the hard
    100-object tenancy limit at this footprint). Hand this list to
    `oke-workload-identity`.

    Expect 3 statements per cluster per service account with everything on:
    `use keys` on hyperswitch's key, `manage objects` on this module's bucket,
    `use email-family`. identity-model.md section 1.2 estimated 2 - it missed
    the KMS grant the real catalog unit has.
  EOT
  value       = local.policy_statements
}

output "statement_count" {
  description = "Number of statements contributed, against the shared policy object's hard 50-statement ceiling."
  value       = length(local.policy_statements)
}

output "authorized_workloads" {
  description = "Every (cluster_id, namespace, service_account) tuple these statements authorise. For audit, not for consumption."
  value       = local.authorized_workloads
}

output "kms_key_id" {
  description = "The KMS key OCID this workload was granted `use keys` on - hyperswitch's key, echoed so the cross-module edge is visible without reading statements."
  value       = var.kms_key_id
}

output "bucket_name" {
  description = "Bucket name. Replaces AWS s3_bucket_id/_arn - OCI addresses a bucket by (namespace, name), so there is no ARN to emit."
  value       = one(oci_objectstorage_bucket.this[*].name)
}

output "bucket_namespace" {
  description = "The tenancy's Object Storage namespace. No AWS counterpart, and required by every consuming API call - bucket names are unique within it rather than globally."
  value       = data.oci_objectstorage_namespace.this.namespace
}

output "bucket_lifecycle_policy_id" {
  description = "OCID of the lifecycle policy, if any rules were emitted. A separate resource on OCI, unlike AWS's inline lifecycle_rule block."
  value       = one(oci_objectstorage_object_lifecycle_policy.this[*].id)
}

output "email_domain_id" {
  description = "OCID of the verified email domain in effect - hyperswitch's, when shared (the recommended default), or this module's own when email.create is true."
  value       = local.email_domain_id
}

output "email_sender_id" {
  description = "OCID of the approved sender in effect."
  value       = local.email_sender_id
}

output "email_domain_is_shared" {
  description = "True when this module consumes hyperswitch's verified domain rather than owning one. The recommended posture: both modules send as the same logical sender today, so two verified domains would be duplicated DNS verification for no isolation benefit (check sheet section 4.2). Oracle gate item, not yet consulted."
  value       = local.email_enabled && !local.email_create
}

output "compartment_id" {
  description = "Compartment these resources live in, and the default location term of every statement emitted."
  value       = var.compartment_id
}

output "region" {
  description = "Region, echoed from the input."
  value       = var.region
}
