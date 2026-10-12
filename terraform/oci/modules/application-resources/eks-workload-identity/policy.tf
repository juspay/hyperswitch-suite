resource "oci_identity_policy" "federated_workload" {
  compartment_id = var.compartment_id
  name           = var.policy_name
  description = coalesce(
    var.policy_description,
    "OCI grants for the federated AWS EKS (hyperops) workload authenticated via Identity Propagation Trust ${var.trust_name}. Statements are contributed by application modules."
  )

  statements = local.all_statements

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # --- Fail-open guards -----------------------------------------------------
    # Each catches a federated statement that would grant far more than
    # intended while looking correct. These run at plan time, not apply time.

    precondition {
      condition     = length(local.statements_missing_type) == 0
      error_message = "Statement(s) use `any-user` without pinning request.principal.type (workload / identityfederateddomainapp / cluster) and are not an `allow service ...` bootstrap - grants every principal in the tenancy: ${jsonencode(local.statements_missing_type)}"
    }

    precondition {
      condition     = length(local.statements_missing_sa) == 0
      error_message = "Federated statement(s) are missing request.principal.name='system:serviceaccount:<ns>:<sa>'. Each omission silently widens to every federated workload in the tenancy: ${jsonencode(local.statements_missing_sa)}"
    }

    precondition {
      condition     = length(local.statements_missing_issuer) == 0
      error_message = "Federated statement(s) are missing request.principal.ext_iss (the EKS OIDC issuer). Add a claim_propagation with name='ext_iss' and value=<EKS issuer> so these stay pinned to one exact issuer: ${jsonencode(local.statements_missing_issuer)}"
    }

    precondition {
      condition     = length(local.statements_with_named_compartment) == 0
      error_message = "Statement(s) use `in compartment <name>` instead of `in compartment id <ocid>`. The OCI API lowercases compartment names, producing a perpetual Terraform diff: ${jsonencode(local.statements_with_named_compartment)}"
    }

    # --- Limits ---------------------------------------------------------------
    precondition {
      condition     = length(local.all_statements) <= var.max_statements
      error_message = "This policy has ${length(local.all_statements)} statements against a cap of ${var.max_statements} (OCI's hard limit is 50 per object and 500 per compartment hierarchy). Do NOT give an app its own policy object."
    }
  }
}