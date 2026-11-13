resource "oci_core_network_security_group" "workers" {
  for_each = var.profiles

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-${each.key}-workers-nsg"
  freeform_tags  = local.freeform_tags
}

resource "oci_core_network_security_group" "pods" {
  for_each = var.profiles

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-${each.key}-pods-nsg"
  freeform_tags  = local.freeform_tags
}
