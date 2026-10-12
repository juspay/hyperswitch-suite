# Module-owned, deliberately EMPTY NSG. Rules are written by composition/security-rules,
# the security-last phase, which reads cassandra_nsg_id from this module's outputs.

resource "oci_core_network_security_group" "cassandra" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# Static network identity.
# No reattachable VNIC on OCI; the stable half of the identity is a RESERVED private
# IP whose vnic_id is updatable. For gossip: an address that moves without the
# re-point step marks the node DOWN until the IP is re-pointed and the node rejoins.
# Ordering - create_before_destroy on the instance, then the in-place vnic_id update,
# then destroy - keeps that window at zero and needs a runbook step.
# This is a SECONDARY IP on the primary VNIC, so the guest adds it to the interface at boot.

resource "oci_core_private_ip" "node" {
  count = var.node_count

  vnic_id = data.oci_core_vnic_attachments.node[count.index].vnic_attachments[0].vnic_id

  lifetime   = "RESERVED"
  ip_address = local.node_ip_addresses[count.index]

  display_name = "${local.name_prefix}-${count.index}-ip"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # A re-point must never be expressed as destroy-and-recreate - that releases
    # the address and hands the ring a new one.
    create_before_destroy = true
  }
}
