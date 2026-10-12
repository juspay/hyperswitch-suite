# =============================================================================
# Module-owned network access-control object (check sheet feature 8)
# =============================================================================
# NSG, not a VCN security list - oci/network-security-model.md section 5,
# Option A. Created EMPTY: catalog/units/oci/security-rules writes the rules in
# the last stack phase, reading nsg_id from this module's outputs.
#
# THIS IS THE ONE NSG IN THE WHOLE PORT THAT CANNOT END UP WITH ZERO INGRESS
# RULES, and the difference from AWS is not cosmetic.
#
# The AWS module's security group has NO ingress_rules at all. That is
# achievable there because SSM Session Manager is agent-based: the SSM Agent on
# the instance makes only OUTBOUND calls to the SSM control plane, and the
# operator's session is brokered through that outbound channel. Nothing ever
# connects inbound, so nothing needs to be allowed inbound.
#
# OCI Bastion is a session BROKER, not an agent-based transport. Every session
# type it offers - Managed SSH, SSH Port Forwarding, Dynamic (SOCKS5) Port
# Forwarding - ends with the bastion's private endpoint opening a connection TO
# the target on the target port. Oracle's own setup documentation says to
# "verify that the target resource allows incoming traffic from the bastion".
# There is no configuration under which that inbound rule can be dropped.
#
# So the rule security-rules must write here is:
#     ingress, TCP 22, source = <bastion_private_endpoint_ip>/32
# and bastion_private_endpoint_ip is exported from this module for exactly that
# purpose. OCI Bastion narrows the source to ONE IP instead of the internet,
# which is a good posture - but it is one rule, not zero, and "match AWS's
# zero-ingress security group" is not an instruction anyone can carry out here.
#
# Per-VNIC NSG count for this module: 1, against the hard cap of 5.

resource "oci_core_network_security_group" "this" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.display_name}-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
