# -----------------------------------------------------------------------------
# Output contract. EVERY output changes (check sheet feature 7, SUBSTITUTE).
#
#   role_arn                     -> NONE. No annotation exists to consume it.
#                                   Do not map it to a policy OCID: a chart that
#                                   annotates a service account with a policy
#                                   OCID looks configured and is not.
#   role_name/role_id/_unique_id -> owned by the shared policy object, which
#                                   this module does not create. Not re-exported.
#   oidc_provider_urls           -> NONE. No OIDC provider is registered.
#   cluster_service_accounts     -> authorized_workloads
#   secrets_manager_policy_json  -> policy_statements
#   region                       -> region (unchanged; the SecretStore needs it)
#   -                            -> vault_id (new, required by the SecretStore)
# -----------------------------------------------------------------------------

output "policy_statements" {
  description = <<-EOT
    The operator's grants, rendered as normalised, sorted `oci_identity_policy`
    statement strings. THIS IS THE IDENTITY - trust and permission collapse into
    the same string on OCI.

    Wire into the environment's shared `oke-workload-identity` policy object.
    Expect exactly `2 x len(cluster_ids)` statements when `secret_ids` and
    `additional_grants` are empty: one `read secret-bundles` (the value) and one
    `read secrets` (the metadata) per cluster.
  EOT
  value       = local.policy_statements

  precondition {
    condition = alltrue([
      for s in local.rendered_statements :
      can(regex("request\\.principal\\.type='workload'", s))
      && can(regex("request\\.principal\\.namespace='[^']+'", s))
      && can(regex("request\\.principal\\.service_account='[^']+'", s))
      && can(regex("request\\.principal\\.cluster_id='[^']+'", s))
    ])
    error_message = "A rendered statement is missing one of the four request.principal.* conditions. That fails OPEN: a missing cluster_id grants every cluster in the tenancy, a missing service_account grants every pod in the namespace, and the OCI API accepts both without error."
  }
}

output "workload_grants" {
  description = "The same grants in `oke-workload-identity`'s structured input shape (cluster expansion is that module's job). PREFER THIS over policy_statements when wiring the shared policy: the canonical renderer cannot forget a `where` condition."
  value       = local.workload_grants
}

output "authorized_workloads" {
  description = "Every (cluster_id, namespace, service_account) tuple these statements authorise. Replaces the AWS module's `cluster_service_accounts` output. Audit surface, not consumable by a workload."
  value       = local.authorized_workloads
}

output "statement_count" {
  description = "Statements this module contributes to the shared policy object, against a hard cap of 50 per object and 500 per compartment hierarchy. Grows as 2 x len(secret_ids) x len(cluster_ids) once per-secret scoping is enabled."
  value       = length(local.policy_statements)
}

output "vault_id" {
  description = "OCID of the vault ESO reads from. NEW, no AWS counterpart - Secrets Manager was implicit per region and account. Consumed by the SecretStore's `spec.provider.oracle.vault`."
  value       = var.vault_id
}

output "vault_compartment_id" {
  description = "Compartment the grants are scoped to. Equals compartment_id unless the vault lives elsewhere, in which case a workload mapping is also required."
  value       = local.secrets_compartment_id
}

output "region" {
  description = "Region identifier. Unchanged from AWS, and still needed - the SecretStore requires `spec.provider.oracle.region`."
  value       = var.region
}

output "workload_mapping_ids" {
  description = "OCIDs of any cross-compartment workload mappings created. Empty in the recommended layout, where the vault sits inside the cluster's compartment subtree."
  value       = { for k, m in oci_containerengine_cluster_workload_mapping.vault : k => m.id }
}

output "secret_store_config" {
  description = <<-EOT
    The exact `spec.provider.oracle` block ESO's SecretStore needs, emitted as a
    map so the chart values cannot be assembled from memory.

    `principalType = "Workload"` is hard-coded here and is the reason this
    output exists. ESO's Oracle provider DEFAULTS TO `InstancePrincipal`: omit
    the field and the operator authenticates as the worker node instead of the
    workload, which will very often appear to work - the node principal tends to
    hold enough access - while granting every pod on that node the same secret
    access and destroying per-pod audit attribution. There is no error and no
    warning. This module creates no dynamic group and no instance-principal
    grant precisely so that misconfiguration fails loudly instead.

    `serviceAccountRef.namespace` is deliberately absent: it is REQUIRED for a
    ClusterSecretStore and MUST NOT be set for a namespaced SecretStore, whose
    referenced service account must live in the store's own namespace. Add it at
    the manifest layer only if the store is cluster-scoped.

    Smoke test for rung 6: assert the OCI Audit event for GetSecretBundle names
    a WORKLOAD principal, not an instance OCID.
  EOT
  value = {
    vault         = var.vault_id
    region        = var.region
    principalType = "Workload"
    serviceAccountRef = {
      name = var.k8s_service_account_name
    }
  }
}
