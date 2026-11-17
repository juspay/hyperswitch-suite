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
# Two consequences:
#
#   1. There is no service_linked_role_arn / _name to output. Nothing replaces
#      them 1:1; a policy OCID is the closest thing and it is a different object.
#   2. This is usually a COMPARTMENT-LEVEL, once-per-tenancy concern rather than
#      a per-cluster one, which is why create_service_policy defaults to FALSE.
#      If a shared identity module already grants it, creating a second policy
#      here is duplication, not safety. Whether that shared module exists is
#      check sheet open question 9 / section 4.6, UNRESOLVED.
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
# Check sheet section 8 item 2: ORACLE GATE - consulted 2026-11-17.

resource "oci_identity_policy" "service" {
  count = var.create_service_policy ? 1 : 0

  compartment_id = local.policy_scope_compartment
  name           = "${local.display_name}-service-policy"
  description    = "Allows the OCI Search with OpenSearch control plane to attach ${local.display_name} to the customer VCN"

  statements = local.service_policy_statements

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
