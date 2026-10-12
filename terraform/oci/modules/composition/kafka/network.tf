# Module-owned, deliberately EMPTY NSGs
# NSG rules belong to composition/security-rules (the security-last phase),
# which reads broker_nsg_id / controller_nsg_id - adding rules here reintroduces
# the dependency cycle the split exists to break.

resource "oci_core_network_security_group" "broker" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-broker-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_network_security_group" "controller" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-controller-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# Static network identity
# OCI has no detach-and-reattach NIC object; the stable identity is the PRIVATE
# IP (lifetime = "RESERVED"), kept alive independently of the VNIC and re-pointed
# to a replacement VNIC via create_before_destroy + vnic_id update. The address
# is a SECONDARY IP on the primary VNIC, so the guest must add it to the
# interface at boot (Oracle Cloud Agent / oci-network-config does this).

resource "oci_core_private_ip" "broker" {
  count = var.broker_count

  vnic_id = data.oci_core_vnic_attachments.broker[count.index].vnic_attachments[0].vnic_id

  # "Reserved" is the whole point: an EPHEMERAL private IP dies with its VNIC,
  # which is what this resource exists to avoid.
  lifetime = "RESERVED"

  # null lets OCI allocate from broker_subnet_id and hold that address.
  ip_address = local.broker_ip_addresses[count.index]

  display_name = "${local.name_prefix}-broker-${count.index}-ip"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # A re-point must never become destroy-and-recreate, which would release the
    # address and hand the cluster a new one.
    create_before_destroy = true
  }
}

resource "oci_core_private_ip" "controller" {
  count = var.controller_count

  vnic_id      = data.oci_core_vnic_attachments.controller[count.index].vnic_attachments[0].vnic_id
  lifetime     = "RESERVED"
  ip_address   = local.controller_ip_addresses[count.index]
  display_name = "${local.name_prefix}-controller-${count.index}-ip"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    create_before_destroy = true
  }
}
