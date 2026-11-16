# -----------------------------------------------------------------------------
# ONE policy object. Per environment. Not per app, not per region.
#
# There is deliberately no `count` and no `for_each` on this resource, and no
# `app_name` variable anywhere in the module. That is the structural guarantee:
# a caller cannot instantiate this module once and get several policy objects,
# and the only way to add an app's permissions is to contribute STATEMENTS
# (`workload_grants` / `statements`) into this shared object.
#
# The arithmetic behind that, from identity-model.md section 3.7:
#   * 100 policy objects per tenancy, hard-limited today;
#   * one object per app per region root at the current AWS footprint is
#     12 apps x 11 roots = 132 objects - unbuildable;
#   * `name` and `compartment_id` are both NOT UPDATABLE, so discovering this
#     after the fact means destroying and recreating every identity in the
#     tenancy, with a window in which every pod loses access.
#
# The cost of the choice is the other limit: 50 statements per policy object,
# enforced as a precondition below. When an environment outgrows it the fix is
# a SECOND instantiation of this module with a different environment-scoped
# name (e.g. `<project>-<env>-workload-identity-data`) splitting the statement
# set by tier - never a policy object per app. That split is a gate item
# (framework section 4.6) and must be consulted before it is made.
# -----------------------------------------------------------------------------

resource "oci_identity_policy" "workload_identity" {
  compartment_id = var.compartment_id
  name           = var.policy_name
  description = coalesce(
    var.policy_description,
    "OKE workload identity grants for ${var.policy_name}. Managed by Terraform module oke-workload-identity; statements are contributed by application modules."
  )

  statements   = local.all_statements
  version_date = var.version_date

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # --- Fail-open guards -----------------------------------------------------
    # Each of these catches a statement that would grant far more than intended
    # while looking correct. They run at plan time, not apply time.

    precondition {
      condition     = length(local.statements_without_principal_type) == 0
      error_message = "Statement(s) use `any-user` without `request.principal.type='workload'`, which grants EVERY user, instance, resource and service principal in the tenancy: ${jsonencode(local.statements_without_principal_type)}"
    }

    precondition {
      condition     = length(local.statements_missing_conditions) == 0
      error_message = "Workload statement(s) are missing one of request.principal.namespace / .service_account / .cluster_id. Each omission silently widens the grant to every pod in the namespace or every cluster in the tenancy: ${jsonencode(local.statements_missing_conditions)}"
    }

    precondition {
      condition     = length(local.statements_with_unknown_cluster) == 0
      error_message = "Statement(s) pin a request.principal.cluster_id that is not in var.cluster_ids. Add the cluster to cluster_ids so the policy's blast radius stays accurately described: ${jsonencode(local.statements_with_unknown_cluster)}"
    }

    precondition {
      condition     = length(local.statements_with_named_compartment) == 0
      error_message = "Statement(s) use `in compartment <name>` instead of `in compartment id <ocid>`. The OCI API lowercases compartment names in policy text, producing a perpetual Terraform diff: ${jsonencode(local.statements_with_named_compartment)}"
    }

    # --- Limits ---------------------------------------------------------------

    precondition {
      condition     = length(local.all_statements) <= var.max_statements
      error_message = "This policy has ${length(local.all_statements)} statements against a cap of ${var.max_statements} (OCI's hard per-policy-object limit is 50). Do NOT resolve this by giving an app its own policy object - the tenancy limit is 100 objects and both `name` and `compartment_id` are non-updatable. Split by tier into a second environment-scoped policy instead, and consult the oracle gate first."
    }
  }
}
