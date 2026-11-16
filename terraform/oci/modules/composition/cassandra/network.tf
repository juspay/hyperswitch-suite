# =============================================================================
# Module-owned, deliberately EMPTY NSG (check sheet feature 4, FULL)
# =============================================================================
# NSGs, never VCN security lists - network-security-model.md Option A. An NSG is
# membership-based and referenceable as a rule SOURCE, which is what makes it the
# close analogue of aws_security_group.
#
# The AWS module writes 2 self ingress/egress rules inline. Neither is ported
# here. They belong to composition/security-rules, the security-last phase, which
# reads cassandra_nsg_id from this module's outputs. Adding rules here
# reintroduces the dependency cycle the split exists to break.
#
# Feature 5 (private egress to cloud APIs) has no resource here at all:
# vpc_endpoint_security_group_id disappears from the input surface entirely,
# because on OCI that path is a Service Gateway created once by vpc-network and
# routed per-tier.

resource "oci_core_network_security_group" "cassandra" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# =============================================================================
# Static network identity (SUBSTITUTE - check sheet feature 2, section 4.2)
# =============================================================================
# Identical mechanism to ../kafka/network.tf; read that file's long note for the
# full derivation. In short:
#
#   AWS builds an aws_network_interface per node BEFORE the instance and attaches
#   the instance to it. An ENI survives detach/reattach to a DIFFERENT instance,
#   which is what lets a node be replaced without its gossip identity changing.
#
#   OCI HAS NO SUCH OBJECT. A VNIC is created for a specific instance_id and is
#   not reattachable. The stable half of the identity is the private IP:
#   oci_core_private_ip with lifetime = "RESERVED", whose vnic_id is updatable.
#
# For Cassandra specifically the consequence is a gossip one: an address that
# moves without the re-point step gets the replaced node marked DOWN by its peers
# until the reserved IP is re-pointed and the node rejoins. Ordering discipline -
# create_before_destroy on the instance, then the in-place vnic_id update, then
# destroy - is what keeps that window at zero, and it needs a runbook step, not
# only a resource graph, until it has been exercised once in dev.
#
# Note also that this is a SECONDARY IP on the primary VNIC: the guest OS must
# add it to the interface at boot (Oracle Cloud Agent / oci-network-config), a
# step AWS's ENI model never required.

resource "oci_core_private_ip" "node" {
  count = var.node_count

  vnic_id = data.oci_core_vnic_attachments.node[count.index].vnic_attachments[0].vnic_id

  lifetime   = "RESERVED"
  ip_address = local.node_ip_addresses[count.index]

  display_name = "${local.name_prefix}-${count.index}-ip"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # A re-point must never be expressed as destroy-and-recreate: that releases
    # the address and hands the ring a new one.
    create_before_destroy = true
  }
}
