# -----------------------------------------------------------------------------
# Output contract.
#
#   role_arn                  -> NONE. No annotation and no cluster-secret field
#                                consumes it. Do not substitute policy_id.
#   role_name/_id/_unique_id  -> owned by the shared policy object.
#   oidc_provider_urls        -> NONE. No OIDC provider is registered.
#   cluster_service_accounts  -> authorized_workloads
#   region                    -> region
#   -                         -> target_compartment_ids (new): where ArgoCD may
#                                deploy, for review and for the cluster
#                                registration manifests.
# -----------------------------------------------------------------------------

output "policy_statements" {
  description = <<-EOT
    ArgoCD's grants as normalised, sorted `oci_identity_policy` statements, for
    the environment's shared `oke-workload-identity` object.

    Expect `len(service_accounts) x len(cluster_ids) x len(grants)` statements.
    With the live AWS shape - five service accounts, one cluster, one deploy
    target and two artefact resource types - that is 15. Against a
    50-per-object cap shared with every other app in the environment.

    DOES NOT INCLUDE cross-tenancy Define/Endorse: those must be attached at the
    tenancy root and are emitted separately as `cross_tenancy_statements`.
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
    error_message = "A rendered statement is missing one of the four request.principal.* conditions. This is the identity that deploys everything else: a statement without cluster_id grants tenancy-wide deploy rights to any cluster, silently."
  }

  precondition {
    condition     = alltrue([for s in local.policy_statements : !can(regex("all-resources", s))])
    error_message = "A statement grants `all-resources`. That is Oracle's ArgoCD tutorial shorthand and it hands ArgoCD full control of the compartment - far wider than the sts:AssumeRole-on-two-roles plus S3-read it replaces."
  }
}

output "cross_tenancy_statements" {
  description = <<-EOT
    `Define` + `Endorse` statements for deploying into another TENANCY, empty
    unless `cross_tenancy_targets` is set.

    SEPARATE FROM policy_statements BECAUSE THEY BELONG SOMEWHERE ELSE: these
    must be attached at the MANAGEMENT TENANCY ROOT, with matching
    `Define`/`Admit` in the target tenancy root. The shared workload-identity
    object is attached at the environment compartment and cannot carry them.

    UNVERIFIED. Oracle documents this construction with
    `request.principal.type = 'nodepool'`; `'workload'` is documented neither
    way. Do not build on this output until check sheet question 1 is answered
    empirically (two tenancies, one Endorse, one Admit, one API call from a
    pod). If it does not work, the fallback is a static API key for the remote
    tenancy - a long-lived credential this port otherwise removes.
  EOT
  value       = local.cross_tenancy_statements
}

output "workload_grants" {
  description = "The same grants in `oke-workload-identity`'s structured shape, one entry per (grant x service account). Preferred over policy_statements when wiring the shared policy."
  value       = local.workload_grants
}

output "authorized_workloads" {
  description = "Every (cluster_id, namespace, service_account) tuple authorised. Replaces `cluster_service_accounts`. Unlike the GCP module, ALL service accounts appear here - GCP's 1:1 Workload Identity binding silently leaves all but the first unbound."
  value       = local.authorized_workloads
}

output "statement_count" {
  description = "Statements contributed to the shared policy object. The widest identity in the platform after `vector` - watch this against the 50-per-object and 500-per-hierarchy caps."
  value       = length(local.policy_statements)
}

output "target_compartment_ids" {
  description = "Compartments ArgoCD may deploy into. NEW output with no AWS counterpart: the AWS module's equivalent knowledge lived in cross_account_roles. Consumed for review and by the cluster-registration manifests, which are not Terraform-managed."
  value       = var.target_compartment_ids
}

output "artifact_compartment_id" {
  description = "Compartment holding the artefact buckets, or null when no object-storage grant is issued."
  value       = var.artifact_compartment_id
}

output "artifact_grant_needs_second_policy_object" {
  description = "True when the artefact compartment is not the environment compartment, which means its `read objects` statements cannot live in the environment-scoped shared policy object - a policy reaches only its own compartment and descendants, and a sibling `shared` compartment is neither. When true, budget a SECOND policy object attached to that compartment against the 100-per-tenancy limit."
  value       = var.artifact_compartment_id != null && var.artifact_compartment_id != var.compartment_id
}

output "workload_mapping_ids" {
  description = "OCIDs of cross-compartment workload mappings created, keyed `<cluster>|<namespace>|<target>`. Empty in the recommended layout."
  value       = { for k, m in oci_containerengine_cluster_workload_mapping.targets : k => m.id }
}

output "region" {
  description = "Region identifier. Unchanged from AWS."
  value       = var.region
}
