# NSG, not a VCN security list. Created EMPTY; catalog/units/oci/security-rules
# writes the rules in the last stack phase, reading nsg_id from outputs.
#
# THIS NSG CANNOT END UP WITH ZERO INGRESS RULES. OCI Bastion is a session
# broker: every session type ends with the bastion's private endpoint opening a
# connection TO the target. security-rules must write:
#     ingress, TCP 22, source = <bastion_private_endpoint_ip>/32
# The AWS zero-ingress SG is not achievable here - OCI narrows the source to
# ONE IP instead of the internet, which is a better posture, but it is one rule.

resource "oci_core_network_security_group" "this" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.display_name}-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
