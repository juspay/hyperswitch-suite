resource "oci_identity_policy" "cluster_iam" {
  compartment_id = var.compartment_id
  name           = var.policy_name
  description = coalesce(
    var.policy_description,
    "OKE cluster-service-principal (Cloud Controller Manager) grants for ${var.policy_name}. Managed by Terraform module oke-cluster-iam; statements are contributed by the live root."
  )

  statements   = local.all_statements
  version_date = var.version_date

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # --- Fail-open guards -----------------------------------------------------
    # These run at PLAN time, not apply time. Each catches a statement that
    # would grant far more than intended while looking correct.

    precondition {
      condition     = length(local.statements_without_cluster_principal) == 0
      error_message = "Statement(s) use `any-user` without `request.principal.type='cluster'`, which grants EVERY user, instance, resource and service principal in the tenancy: ${jsonencode(local.statements_without_cluster_principal)}"
    }

    precondition {
      condition     = length(local.statements_with_named_compartment) == 0
      error_message = "Statement(s) use `in compartment <name>` instead of `in compartment id <ocid>`. The OCI API lowercases compartment names in policy text, producing a perpetual Terraform diff: ${jsonencode(local.statements_with_named_compartment)}"
    }

    # --- Limits ---------------------------------------------------------------

    precondition {
      condition     = length(local.all_statements) <= var.max_statements
      error_message = "This policy has ${length(local.all_statements)} statements against a cap of ${var.max_statements} (OCI's hard per-policy-object limit is 50). Do NOT give an app its own policy object - the tenancy limit is 100 objects and both `name` and `compartment_id` are non-updatable."
    }
  }
}