# Module-owned, deliberately EMPTY NSGs
# Two NSGs, keeper and server. Rules belong to composition/security-rules
# (adding them here reintroduces the dependency cycle the split exists to break).

resource "oci_core_network_security_group" "keeper" {
  count = var.create_nsg && var.keeper_count > 0 ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-keeper-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_network_security_group" "server" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-server-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# Static network identity
# Identical mechanism to ../kafka/network.tf (read that file for the derivation).
# ClickHouse-specific blast radius: BOTH tiers' user data bakes peer IPs in via
# {{keeper_ips}} / {{server_ips}}, so a missed re-point breaks every sibling
# node's assumption, not just the replaced one. The address is a SECONDARY IP on
# the primary VNIC the guest must bring up at boot.

resource "oci_core_private_ip" "keeper" {
  count = var.keeper_count

  vnic_id      = data.oci_core_vnic_attachments.keeper[count.index].vnic_attachments[0].vnic_id
  lifetime     = "RESERVED"
  ip_address   = local.keeper_ip_addresses[count.index]
  display_name = "${local.name_prefix}-keeper-${count.index}-ip"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "oci_core_private_ip" "server" {
  count = var.server_count

  vnic_id      = data.oci_core_vnic_attachments.server[count.index].vnic_attachments[0].vnic_id
  lifetime     = "RESERVED"
  ip_address   = local.server_ip_addresses[count.index]
  display_name = "${local.name_prefix}-server-${count.index}-ip"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    create_before_destroy = true
  }
}
