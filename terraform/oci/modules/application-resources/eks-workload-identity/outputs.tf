output "trust_id" {
  description = "OCID of the Identity Propagation Trust. The trust is the one-shot establishment - the deploy workload consumes it, never recreates it."
  value       = oci_identity_domains_identity_propagation_trust.eks.id
}

output "trust_issuer" {
  description = "The EKS OIDC issuer the trust accepts (echo of eks_oidc_issuer). Auditable ground truth of who is trusted."
  value       = oci_identity_domains_identity_propagation_trust.eks.issuer
}

output "trust_active" {
  description = "Whether the trust is currently active (accepting token-exchange requests)."
  value       = oci_identity_domains_identity_propagation_trust.eks.active
}

output "policy_id" {
  description = "OCID of the federated-workload policy. Audit/reference only - NOT a role ARN and NOT annotatable onto a Kubernetes service account."
  value       = oci_identity_policy.federated_workload.id
}

output "policy_name" {
  description = "Name of the federated-workload policy. Tenancy-unique and non-updatable."
  value       = oci_identity_policy.federated_workload.name
}

output "statements" {
  description = "The rendered, normalised, sorted statement list exactly as sent to the API. This is the security boundary in full - review it, do not skim it."
  value       = oci_identity_policy.federated_workload.statements
}

output "authorized_workloads" {
  description = "Every (namespace, service_account, verb, resource_type) tuple this policy authorises, recovered from the final statement text."
  value       = local.authorized_workloads
}

output "statement_count" {
  description = "Number of statements in this policy object, against OCI's hard limit of 50 per object."
  value       = length(local.all_statements)
}

output "statement_headroom" {
  description = "Statements remaining before this policy object hits max_statements. Also watch the separate 500-per-compartment-hierarchy limit."
  value       = var.max_statements - length(local.all_statements)
}

output "compartment_id" {
  description = "Compartment the policy is attached to. Statements can only reach this compartment and its descendants."
  value       = oci_identity_policy.federated_workload.compartment_id
}