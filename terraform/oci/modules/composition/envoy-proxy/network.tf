# Module-owned network access-control objects (NSGs).
# Both are created EMPTY on purpose and filled by the security-rules unit, the
# last stack phase, reading nsg_id / lb_nsg_id from this module's outputs.
# Keeping the object here and the rules there is what breaks the dependency
# cycle with everything that talks to the proxy tier - do not add rules here.
# NSGs, not security lists: only an NSG can be named as a rule source
# (security lists cannot reference a peer group).

resource "oci_core_network_security_group" "instances" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.display_name}-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# The load balancer's own NSG, separate from the instances' so the LB<->instance
# rules are written as NSG-to-NSG references.
resource "oci_core_network_security_group" "lb" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.display_name}-lb-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
