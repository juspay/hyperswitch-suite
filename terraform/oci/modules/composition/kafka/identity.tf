# Node identity
# OCI has no instance-profile object: an instance gets instance-principal
# credentials once it matches a dynamic group and a policy grants that group.
# A dynamic group is TENANCY-level (hence create_identity defaults false and why
# tenancy_ocid exists); its matching rule CANNOT match a freeform tag, so the
# default rule is compartment-scoped and WIDER than the AWS instance profile it
# replaces - narrowing it needs a per-component compartment or a defined-tag
# namespace (var.identity_matching_rule is the escape hatch).

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
