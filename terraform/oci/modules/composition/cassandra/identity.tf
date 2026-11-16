# =============================================================================
# Node identity (SUBSTITUTE - check sheet feature 6, section 4.3)
# =============================================================================
# Identical fork to ../kafka/identity.tf; read that file for the full note.
# The short version:
#
#   * OCI has NO instance-profile object and no attach step. An instance gets
#     instance-principal credentials once it matches a dynamic group's rule and a
#     policy grants that group permissions. Nothing on oci_core_instance
#     references either resource below, and that absence is correct.
#   * A dynamic group is a TENANCY-level object - compartment_id must be the
#     tenancy OCID, which is why create_identity defaults to false.
#   * The matching rule CANNOT match a freeform tag. OCI accepts
#     instance.compartment.id, instance.id, or a DEFINED tag, and no tag
#     namespace exists in this tenancy. The compartment-scoped default is
#     therefore WIDER than the AWS instance profile it replaces.
#
# The AWS role granted EC2 describe, ENI create/delete, instance terminate and
# log write. Only the read and log halves are reproduced: ENI create/delete has
# no OCI counterpart at all, and instance-terminate is a capability worth
# granting deliberately rather than by default.
#
# framework.md section 4.4 gate item. Check sheet section 8 item 3:
# ORACLE GATE ITEM, NOT YET CONSULTED.

resource "oci_identity_dynamic_group" "nodes" {
  count = local.create_identity ? 1 : 0

  compartment_id = var.tenancy_ocid
  name           = "${local.name_prefix}-nodes"
  description    = "Cassandra nodes for ${local.name_prefix}"

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
