# =============================================================================
# Module-owned network access-control objects (check sheet feature 14)
# =============================================================================
# NSGs, not VCN security lists. The binding decision is
# docs/multi-cloud-parity/oci/network-security-model.md section 5, Option A:
# every workload permission is an NSG rule, no composition module creates an
# oci_core_security_list, and the VCN's default security list is emptied by
# vpc-network. Security lists union (OR) with NSG rules, so a permissive list
# silently widens every NSG on every VNIC in the subnet - which is why the
# model has exactly one exception and this module is not it.
#
# NSGs are also the closer analogue of aws_security_group for the specific
# rules this module needs: the AWS module scopes its LB<->ASG rules by
# source_security_group_id, and only an NSG can be named as a rule source
# ("you can specify an NSG instead of a CIDR ... to control traffic between
# two NSGs in the same VCN"). A security list cannot reference a peer group.
#
# Both are created EMPTY, on purpose, and stay empty. catalog/units/oci/
# security-rules - the last stack phase - writes the rules into them via
# standalone oci_core_network_security_group_security_rule resources, reading
# nsg_id and lb_nsg_id from this module's outputs. This mirrors
# composition/database/network.tf exactly and exists for the same reason:
# keeping the object here and the rules there is what breaks the dependency
# cycle between the proxy tier and everything that talks to it. Do not add
# rules to this file to "simplify"; that reintroduces the cycle the split
# exists to break.
#
# Structurally this is CLEANER than AWS, not merely equivalent: the OCI NSG
# resource has no inline-rule arguments at all, so two Terraform states can
# never contend over the same rule set the way an aws_security_group with
# inline ingress blocks fights aws_security_group_rule.
#
# Per-VNIC NSG count for this module: 1 (instances), against OCI's hard,
# non-increasable cap of 5 per VNIC.

resource "oci_core_network_security_group" "instances" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.display_name}-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# The load balancer's own NSG, the counterpart of the AWS module's
# module.lb_security_group. Separate from the instances' NSG because the
# LB<->instance rules are written as NSG-to-NSG references, which needs two
# distinct groups to reference. OCI load balancers do support NSG membership
# (network_security_group_ids on oci_load_balancer_load_balancer), unlike the
# NLB-front-end question left open for squid-proxy.
resource "oci_core_network_security_group" "lb" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.display_name}-lb-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
