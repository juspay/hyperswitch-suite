# =============================================================================
# Module-owned, deliberately EMPTY NSGs (check sheet feature 4, FULL)
# =============================================================================
# Two NSGs, keeper and server, mirroring the AWS module's two security groups.
# The AWS module writes 10 aws_security_group_rule resources inline (keeper self
# and cross traffic, server self and cross traffic, plus conditional VPC-endpoint
# egress). NONE are ported here - they belong to composition/security-rules, the
# security-last phase, which reads keeper_nsg_id and server_nsg_id from this
# module's outputs. Adding rules here reintroduces the dependency cycle the split
# exists to break.
#
# vpc_endpoint_security_group_id disappears from the input surface entirely:
# private egress to cloud APIs on OCI is a Service Gateway created once by
# vpc-network and routed per-tier, not a rule against an endpoint's SG.

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

# =============================================================================
# Static network identity (SUBSTITUTE - check sheet feature 3, section 4.2)
# =============================================================================
# Identical mechanism to ../kafka/network.tf; read that file for the derivation.
#
# What is specific to ClickHouse: BOTH tiers' user data bakes peer IPs in at
# apply time through {{keeper_ips}} / {{server_ips}} substitution. An address
# that moves without the re-point step therefore breaks that substitution's
# assumption for EVERY OTHER NODE in the cluster, not just the replaced one -
# and those siblings will not notice until they are individually refreshed.
# That is a wider blast radius than kafka's voter list or cassandra's gossip.
#
# The address is a SECONDARY IP on the primary VNIC: the guest must add it to
# the interface at boot (Oracle Cloud Agent / oci-network-config).

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
