# Node identity
# Identical fork to ../kafka/identity.tf (read that file for the full note):
# a dynamic group is TENANCY-level (hence create_identity defaults false), its
# matching rule CANNOT match a freeform tag, so the default compartment-scoped
# rule is WIDER than the AWS instance profile it replaces. Unlike the other two
# modules, the AWS clickhouse original already expected callers to override its
# policy set, so var.policy_statements here is what should actually be reviewed.

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
