resource "oci_core_network_security_group" "workers" {
  for_each = local.dedicated_nsg_pool_names

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.cluster_name}-${each.key}-workers-nsg"
  freeform_tags  = local.common_freeform_tags
}

resource "oci_core_network_security_group" "pods" {
  for_each = local.dedicated_nsg_pool_names

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.cluster_name}-${each.key}-pods-nsg"
  freeform_tags  = local.common_freeform_tags
}
