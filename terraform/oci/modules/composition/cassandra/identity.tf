# Node identity.
# OCI has no instance-profile object: an instance gets instance-principal credentials
# once it matches a dynamic group rule and a policy grants that group permissions.
# The dynamic group is tenancy-level (hence create_identity defaults to false), and
# its matching rule cannot use a freeform tag, so the compartment-scoped default is
# WIDER than the AWS instance profile it replaces. Permissions are narrowed to read
# + log write; instance-terminate is granted deliberately, not by default.

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
