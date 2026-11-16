# =============================================================================
# Node identity (SUBSTITUTE - check sheet feature 6, section 4.3)
# =============================================================================
# Identical fork to ../kafka/identity.tf; read that file for the full note.
#
#   * OCI has NO instance-profile object and no attach step. Instance-principal
#     credentials arrive once an instance matches a dynamic group's rule and a
#     policy grants that group permissions.
#   * A dynamic group is TENANCY-level, which is why create_identity defaults to
#     false and why tenancy_ocid exists as an input.
#   * The matching rule CANNOT match a freeform tag - only
#     instance.compartment.id, instance.id, or a DEFINED tag, and no tag
#     namespace exists in this tenancy. The default rule is therefore WIDER than
#     the AWS instance profile it replaces.
#
# ONE DIFFERENCE FROM THE OTHER TWO MODULES: the AWS clickhouse module already
# expects callers to override its policy set (iam_inline_policies /
# iam_managed_policy_arns) rather than accept the broad EC2/ASG/STS default. So
# var.policy_statements is the input that should actually be reviewed here, and
# the module's own default is deliberately narrow rather than a port of the AWS
# default.
#
# framework.md section 4.4 gate item. Check sheet section 8 item 3:
# ORACLE GATE ITEM, NOT YET CONSULTED.

resource "oci_identity_dynamic_group" "nodes" {
  count = local.create_identity ? 1 : 0

  compartment_id = var.tenancy_ocid
  name           = "${local.name_prefix}-nodes"
  description    = "ClickHouse keeper and server instances for ${local.name_prefix}"

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
