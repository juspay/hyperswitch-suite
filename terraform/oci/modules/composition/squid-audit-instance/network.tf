# =============================================================================
# Module-owned access control - the SSH NSG
# =============================================================================
# NSG, not a VCN security list - network-security-model.md section 5 Option A.
# Unlike the pooled squid-proxy module (empty NSG filled cross-unit by
# security-rules), this audit box writes its OWN SSH ingress rule inline: it is
# self-contained and not part of the security-rules last-phase fan-in.

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
# module does. The variable is REQUIRED, so a plan cannot silently produce an
# unreviewed box with an unconstrained or empty source.
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