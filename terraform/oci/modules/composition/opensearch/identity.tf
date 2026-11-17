# =============================================================================
# Service control-plane authorization (SUBSTITUTE - feature 12, section 4.6)
# =============================================================================
# AWS creates an aws_iam_service_linked_role so the OpenSearch control plane can
# provision ENIs inside the customer's VPC on their behalf. It is one explicit,
# one-time object with an ARN.
#
# OCI HAS NO SERVICE-LINKED-ROLE CONCEPT. The equivalent is a service POLICY:
# a statement granting a named service principal permission to use the
# virtual-network family in a compartment, which must exist BEFORE the first
# cluster can attach to a customer VCN - the same ordering AWS's service-linked
# role encodes, expressed as a policy instead of a role.
#
# Three consequences:
#
#   1. There is no service_linked_role_arn / _name to output. Nothing replaces
#      them 1:1; a policy OCID is the closest thing and it is a different object.
#   2. This is usually a COMPARTMENT-LEVEL, once-per-tenancy concern rather than
#      a per-cluster one, which is why create_service_policy defaults to FALSE.
#      If a shared identity module already grants it, creating a second policy
#      here is duplication, not safety.
#   3. IAM writes are HOME-REGION-ONLY: oci_identity_policy must be written
#      under a provider homed in the TENANCY HOME REGION, while the cluster
#      needs the unit's regional provider. The policy resource therefore binds
#      to the ALIASED provider configuration oci.home, and the unit enabling
#      create_service_policy must supply that alias (the prod root.hcl already
#      generates the regional default and the home alias together in one
#      provider.tf).
#
# THE SERVICE PRINCIPAL NAME IS VERIFIED (2026-11-17): `opensearch`, and the
# four-statement grant set is Oracle's own documented prerequisite for this
# resource (see locals.tf for citations). The earlier version of this block
# carried an inference here; Oracle's prerequisite documentation has since
# been located and confirms both the principal and a BROADER statement set
# than the original single `use virtual-network-family` aggregate - a use-level
# aggregate never grants the `manage vnics` / `manage vcns` verbs the control
# plane needs to create cluster-node VNICs. Override with
# var.service_policy_statements if a narrower grant is ever proven sufficient.

resource "oci_identity_policy" "service" {
  count = var.create_service_policy ? 1 : 0

  # IAM writes must run from the tenancy home region; the cluster in cluster.tf
  # runs under the unit's regional provider. Two provider configurations,
  # one unit.
  provider = oci.home

  compartment_id = local.policy_scope_compartment
  name           = local.service_policy_name
  description    = local.service_policy_description

  statements   = local.service_policy_statements
  version_date = var.service_policy_version_date

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # Plan-time guards: fail CLOSED on a statement granting to the wrong
  # principal, on the named-compartment form the OCI API lowercases (a
  # perpetual-diff source), or on exceeding the per-policy statement cap.
  lifecycle {
    precondition {
      condition     = length(local.service_policy_statements_without_service_principal) == 0
      error_message = "service_policy_statements must name `service opensearch` as the principal - a statement granting to anything else changes the security boundary: ${jsonencode(local.service_policy_statements_without_service_principal)}"
    }

    precondition {
      condition     = length(local.service_policy_statements_with_named_compartment) == 0
      error_message = "service_policy_statements must use `in compartment id <ocid>`, not `in compartment <name>` - the OCI API lowercases compartment names in policy text, producing a perpetual Terraform diff: ${jsonencode(local.service_policy_statements_with_named_compartment)}"
    }

    precondition {
      condition     = length(local.service_policy_statements) <= var.service_policy_max_statements
      error_message = "This policy has ${length(local.service_policy_statements)} statements against a cap of ${var.service_policy_max_statements} (OCI's hard per-policy-object limit is 50). Do NOT create a second policy object for the same grants - the tenancy limit is 100 objects and both `name` and `compartment_id` are non-updatable."
    }
  }
}
