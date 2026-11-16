# =============================================================================
# Node identity (SUBSTITUTE - check sheet feature 6, section 4.3)
# =============================================================================
# AWS attaches a policy-bearing IAM role to the instance through an
# aws_iam_instance_profile - one object, referenced at launch time.
#
# OCI HAS NO INSTANCE-PROFILE OBJECT AND NO ATTACH STEP. An instance obtains
# instance-principal credentials implicitly once (a) it matches a dynamic
# group's matching rule and (b) a policy grants that dynamic group permissions.
# The matching rule does the binding. Nothing on oci_core_instance references
# either resource below, and that absence is correct - it is not an omission.
#
# Two consequences worth knowing before changing this file:
#
#   1. A dynamic group is a TENANCY-level object. compartment_id must be the
#      tenancy OCID; a child compartment is rejected. That is why this module
#      needs tenancy_ocid at all, and why create_identity defaults to false -
#      most callers will not have tenancy-root write permission, and a module
#      that cannot be applied without it is worse than one that opts in.
#   2. A dynamic group matching rule CANNOT match on a freeform tag. OCI's rule
#      grammar accepts instance.compartment.id, instance.id, and
#      tag.<namespace>.<key>.value - and that last form is a DEFINED tag, which
#      needs a tag namespace this tenancy does not have yet. So the default rule
#      below is compartment-scoped only: every instance in var.compartment_id
#      matches, not just Kafka's. That is WIDER than the AWS instance profile it
#      replaces, which bound to exactly the instances it was attached to.
#      Narrowing it needs either a per-component compartment or a defined-tag
#      namespace; var.identity_matching_rule is the escape hatch until one
#      exists. This is a real, currently-open security divergence, not a nit.
#
# framework.md section 4.4 flags this as a gate-required identity fork - the same
# fork IRSA hits elsewhere in the programme, applied here to instance-to-cloud-API
# identity. Check sheet section 8 item 3: ORACLE GATE ITEM, NOT YET CONSULTED.

resource "oci_identity_dynamic_group" "nodes" {
  count = local.create_identity ? 1 : 0

  compartment_id = var.tenancy_ocid
  name           = "${local.name_prefix}-nodes"
  description    = "Kafka broker and controller instances for ${local.name_prefix}"

  matching_rule = local.matching_rule

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_identity_policy" "nodes" {
  count = local.create_identity ? 1 : 0

  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-nodes-policy"
  description    = "Instance-principal permissions for ${local.name_prefix} nodes"

  statements = local.policy_statements

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  depends_on = [oci_identity_dynamic_group.nodes]
}
