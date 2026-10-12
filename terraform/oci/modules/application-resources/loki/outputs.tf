# Output contract

output "policy_statements" {
  description = <<-EOT
    This module's contribution to the ONE shared, environment-scoped
    `oci_identity_policy` owned by the `oke-workload-identity` unit. Rendered,
    normalised and sorted.

    THIS MODULE CREATES NO POLICY OBJECT. Hand
    this list to `oke-workload-identity`; do not wrap it in a policy resource in
    the caller.

    Expect exactly ONE statement per cluster: `manage objects` scoped to this
    module's chunk bucket. If you see `use objects` here, something has gone
    wrong - `use` cannot create an object, and Loki writes chunks.
  EOT
  value       = local.policy_statements
}

output "statement_count" {
  description = "Number of statements contributed, against the shared policy object's hard 50-statement ceiling."
  value       = length(local.policy_statements)
}

output "authorized_workloads" {
  description = "Every (cluster_id, namespace, service_account) tuple this module's statements authorise. For audit, not for consumption by a workload."
  value       = local.authorized_workloads
}

output "bucket_name" {
  description = "Chunk bucket name. Replaces AWS s3_bucket_id/_arn - OCI addresses a bucket by (namespace, name) and there is no ARN."
  value       = one(oci_objectstorage_bucket.chunks[*].name)
}

output "bucket_namespace" {
  description = "The tenancy's Object Storage namespace. No AWS counterpart, and needed by every consuming call - Loki's own storage config takes it explicitly."
  value       = data.oci_objectstorage_namespace.this.namespace
}

output "bucket_lifecycle_policy_id" {
  description = "OCID of the chunk-expiry lifecycle policy, or null when bucket_lifecycle_expiry_days is null. A separate resource on OCI, unlike AWS's inline lifecycle_rule."
  value       = one(oci_objectstorage_object_lifecycle_policy.chunks[*].id)
}

output "nsg_id" {
  description = <<-EOT
    OCID of the module-owned, DELIBERATELY EMPTY Network Security Group for
    Loki's query path. Replaces AWS security_group_id / _arn / _name.

    THE CONSUMED OUTPUT: `composition/security-rules`, running in the last stack
    phase, writes both this NSG's frontend ingress rules and the LB-to-node-pool
    rule that AWS's `alb-controller` used to manage for free. Rules do not
    belong in this module - see network.tf for why.
  EOT
  value       = one(oci_core_network_security_group.this[*].id)
}

output "compartment_id" {
  description = "Compartment these resources live in, and the location term of the emitted statement."
  value       = var.compartment_id
}

output "region" {
  description = "Region, echoed from the input. Unchanged from AWS."
  value       = var.region
}
