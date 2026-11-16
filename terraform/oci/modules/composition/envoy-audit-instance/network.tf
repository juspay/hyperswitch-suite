# =============================================================================
# Module-owned access control - the SSH NSG
# =============================================================================
# NSG, not a VCN security list - oci/network-security-model.md section 5,
# Option A. Unlike the pooled envoy-proxy module (whose NSG is created empty
# and filled cross-unit by security-rules), this audit box writes its OWN SSH
# ingress rule inline: it is a self-contained disposvable host reached over the
# VPN, and is deliberately NOT part of the security-rules last-phase NSG
# fan-in. Wiring a slot for a short-lived review box into that graph would
# couple its apply order to a unit whose sole job is cross-unit rules.

resource "oci_core_network_security_group" "this" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.display_name}-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# SSH ingress, one rule per VPN/office source CIDR - OCI's
# oci_core_network_security_group_security_rule takes a SINGLE `source` string,
# so a list fans out into one rule per CIDR exactly as the security-rules unit's
# module does ("one-CIDR-per-rule fan-out"). The rule set as a whole is
# allow-only (NSGs union, no deny), and var.vpn_source_cidrs is REQUIRED, so a
# plan cannot silently produce an unreviewed box with an unconstrained or empty
# source.
resource "oci_core_network_security_group_security_rule" "ssh" {
  for_each = toset(var.vpn_source_cidrs)

  network_security_group_id = oci_core_network_security_group.this[0].id
  description               = "SSH from corporate VPN / office range ${each.key} (security-team audit access)"
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = each.key
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}