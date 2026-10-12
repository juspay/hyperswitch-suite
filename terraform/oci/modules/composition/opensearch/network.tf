# Module-owned, deliberately EMPTY NSG. Same convention as the sibling data-tier
# modules: this module owns the NSG object, and composition/security-rules - the
# security-last stack phase - writes the rules into it by reading nsg_id from
# this module's outputs. Do not add rules here. NSG-gated is like-for-like with
# the AWS module, whose access_policy_statements already use principal ["*"]
# (i.e. whoever can reach it on the network), so the NSG is not weaker. The
# cluster resource takes exactly ONE nsg_id, which is why AWS's four security-
# group variables collapse into create_nsg + nsg_id.

resource "oci_core_network_security_group" "this" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.display_name}-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
