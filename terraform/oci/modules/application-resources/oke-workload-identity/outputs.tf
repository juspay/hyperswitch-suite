# Output contract. No role ARN replacement: OCI names the service account, so
# nothing below is consumable by a workload - these outputs exist for audit.

output "policy_id" {
  description = "OCID of the single workload-identity policy. Audit/reference only - NOT a role ARN, and must not be annotated onto a Kubernetes service account."
  value       = oci_identity_policy.workload_identity.id
}

output "policy_name" {
  description = "Name of the policy. Tenancy-unique and non-updatable; changing it destroys and recreates every identity in it."
  value       = oci_identity_policy.workload_identity.name
}

output "statements" {
  description = "The rendered, normalised, sorted statement list exactly as sent to the API. This is the security boundary in full - review it, do not skim it."
  value       = oci_identity_policy.workload_identity.statements
}

output "authorized_workloads" {
  description = "Every (cluster_id, namespace, service_account) tuple this policy authorises, recovered from the final statement text. The replacement for the AWS module's `cluster_service_accounts` output."
  value       = local.authorized_workloads
}

output "statement_count" {
  description = "Number of statements in this policy object, against OCI's hard limit of 50 per object."
  value       = length(local.all_statements)
}

output "statement_headroom" {
  description = "Statements remaining before this policy object hits `max_statements`. Also watch the separate 500-per-compartment-hierarchy limit, which this module cannot see and which cannot be raised."
  value       = var.max_statements - length(local.all_statements)
}

output "is_bootstrap_only" {
  description = "True while the policy carries only the inert bootstrap statement, i.e. no application module has contributed a grant yet. Must be false before any workload is expected to authenticate."
  value       = local.is_bootstrap_only
}

output "compartment_id" {
  description = "Compartment the policy is attached to. Statements can only reach this compartment and its descendants."
  value       = oci_identity_policy.workload_identity.compartment_id
}
