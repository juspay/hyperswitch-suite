# =============================================================================
# Module-owned, deliberately EMPTY NSGs (check sheet feature 4, FULL)
# =============================================================================
# NSGs, never VCN security lists - the settled decision in
# docs/multi-cloud-parity/oci/network-security-model.md (Option A). An NSG is
# membership-based and referenceable as a rule SOURCE, which makes it the close
# analogue of aws_security_group; a security list attaches to a subnet and would
# put Kafka's access control in vpc-network's hands instead of this module's.
#
# The AWS module writes 8 aws_security_group_rule resources inline here (broker
# self-traffic, controller self-traffic, broker<->controller cross-traffic, and
# conditional HTTPS egress to VPC endpoints). NONE of them are ported into this
# file. They belong to composition/security-rules, the security-last stack phase,
# which reads broker_nsg_id and controller_nsg_id from this module's outputs.
# Adding rules here to "simplify" reintroduces exactly the dependency cycle the
# split exists to break - the same instruction the sibling `database` module's
# network.tf carries.
#
# Feature 5 (private egress to cloud APIs) has no resource here at all: the AWS
# module took vpc_endpoint_security_group_id and wrote an HTTPS egress rule
# against it. On OCI that path is a Service Gateway created once by vpc-network
# and routed per-tier, so the variable disappears from this module's surface
# entirely rather than being renamed.

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

# =============================================================================
# Static network identity (SUBSTITUTE - check sheet feature 3, section 4.2)
# =============================================================================
# THIS IS THE MOST IMPORTANT DIVERGENCE IN THIS MODULE. Read it before changing
# anything below.
#
# AWS builds an aws_network_interface per broker and per controller BEFORE the
# instance exists and attaches the instance to it. An ENI is a top-level object:
# detach it from instance A, attach the SAME object to instance B, and the MAC
# and IP move with it. KRaft's controller quorum is configured with a static
# voter list (node.id@host:port), so that stability is not a nicety - it is what
# lets a broker or controller be replaced (image refresh, shape change, hardware
# retirement) without rewriting every other node's configuration.
#
# OCI HAS NO EQUIVALENT OBJECT. A VNIC is created FOR a specific instance_id
# (oci_core_vnic_attachment.instance_id is required) and there is no documented
# detach-and-reattach-to-a-different-instance operation. The stable half of the
# identity on OCI is the PRIVATE IP, not the NIC: oci_core_private_ip supports
# lifetime = "Reserved", which keeps the address alive independently of the
# VNIC's lifecycle, and its vnic_id argument is updatable.
#
# So the mechanism is IP-centric re-pointing, not NIC-object reuse:
#
#   1. the instance is created with create_before_destroy, so the replacement
#      exists before the original is destroyed;
#   2. data.oci_core_vnic_attachments re-reads the new primary VNIC's OCID;
#   3. oci_core_private_ip.vnic_id updates IN PLACE to that new VNIC - the
#      ip_address does not change, because the private IP object was never
#      destroyed;
#   4. the old instance and its VNIC are destroyed last.
#
# RESIDUAL RISK, and it is real: an apply that runs out of order, or a manual
# intervention that skips step 3, leaves a broker unreachable at the address its
# peers' voter list still names. Note also that this address is a SECONDARY IP
# on the primary VNIC - the guest OS must add it to the interface (Oracle Cloud
# Agent / oci-network-config does this; a hand-rolled image must do it itself),
# which is a boot-time step AWS's ENI model never needed. Both belong in the
# runbook, not only in the resource graph, until exercised once in dev.
#
# GCP, for the record, is NOT the outlier here - OCI is. GCP's port uses
# google_compute_address, a standalone regional object much closer to AWS's ENI.

resource "oci_core_private_ip" "broker" {
  count = var.broker_count

  vnic_id = data.oci_core_vnic_attachments.broker[count.index].vnic_attachments[0].vnic_id

  # "Reserved" is the whole point: an EPHEMERAL private IP is destroyed with its
  # VNIC, which is the behaviour this resource exists to avoid.
  lifetime = "RESERVED"

  # null lets OCI allocate from broker_subnet_id and then hold that address for
  # the life of this object.
  ip_address = local.broker_ip_addresses[count.index]

  display_name = "${local.name_prefix}-broker-${count.index}-ip"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # Never let a re-point be expressed as destroy-and-recreate: that would
    # release the address and hand the cluster a new one, which is precisely the
    # failure this design prevents.
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
