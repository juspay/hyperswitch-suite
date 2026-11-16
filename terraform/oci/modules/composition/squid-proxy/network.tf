# =============================================================================
# Module-owned network access-control objects (check sheet feature 12)
# =============================================================================
# NSGs, not VCN security lists - oci/network-security-model.md section 5,
# Option A. Security-list rules union (OR) with NSG rules, so a permissive list
# silently widens every NSG on every VNIC in the subnet and no NSG can narrow
# it back. That is the wrong trade for the tier that gates every outbound call
# the platform makes.
#
# Created EMPTY. catalog/units/oci/security-rules, the last stack phase, writes
# the rules by reading nsg_id and nlb_nsg_id from this module's outputs. Same
# contract as composition/database/network.tf. Do not add rules here.
#
# ONE SQUID-SPECIFIC INPUT TO THAT DECISION, handed over from the check sheet:
# the AWS module sources its health-check rule from the load balancer's SUBNET
# CIDRs (data.aws_subnet.lb_subnets), not from a security-group reference,
# because an AWS NLB has no stable per-ENI security-group identity to name.
# OCI's NLB DOES expose network_security_group_ids on the balancer itself
# (confirmed on oci_network_load_balancer_network_load_balancer's schema), so
# the nlb NSG below can be named as a rule source and the AWS CIDR workaround
# is NOT needed here. Whether the NLB's health-check probes actually originate
# from a VNIC carrying that NSG is the part still unconfirmed (check sheet §9
# item 2) - if they do not, the health-check ingress rule falls back to the
# nlb subnet's CIDR, which security-rules can read from vpc-network's
# subnet_cidrs_by_tier without any change here.
#
# Per-VNIC NSG count for this module: 1 (instances), against the hard,
# non-increasable cap of 5.

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
