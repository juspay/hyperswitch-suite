output "policy_id" {
  description = "OCID of the cluster-principal policy. Audit/reference only."
  value       = oci_identity_policy.cluster_iam.id
}

output "policy_name" {
  description = "Name of the policy. Tenancy-unique and non-updatable."
  value       = oci_identity_policy.cluster_iam.name
}

output "statements" {
  description = "The rendered, normalised, sorted statement list exactly as sent to the API. Review it, do not skim it - this is the security boundary in full."
  value       = oci_identity_policy.cluster_iam.statements
}

output "statement_count" {
  description = "Number of statements in this policy object, against OCI's hard limit of 50 per object."
  value       = length(local.all_statements)
}

output "statement_headroom" {
  description = "Statements remaining before this policy object hits `max_statements`."
  value       = var.max_statements - length(local.all_statements)
}

output "compartment_id" {
  description = "Compartment the policy is attached to. Statements can only reach this compartment and its descendants."
  value       = oci_identity_policy.cluster_iam.compartment_id
}