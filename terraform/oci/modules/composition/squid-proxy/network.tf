# Module-owned network access-control objects (NSGs).
# NSGs, not VCN security lists; created EMPTY and filled by the security-rules
# unit, the last stack phase, reading nsg_id / nlb_nsg_id from this module's
# outputs. Do not add rules here.
# Unlike an AWS NLB, an OCI NLB exposes network_security_group_ids, so the NLB
# health-check rule can be an NSG-to-NSG reference instead of a subnet-CIDR.
# Whether the NLB's probes actually originate from a VNIC carrying that NSG is
# still unconfirmed; if not, the rule falls back to the nlb subnet's CIDR.

resource "oci_core_network_security_group" "instances" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.display_name}-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_network_security_group" "nlb" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.display_name}-nlb-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
