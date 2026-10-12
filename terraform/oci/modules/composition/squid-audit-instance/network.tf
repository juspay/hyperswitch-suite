# Module-owned SSH NSG (NSG, not a VCN security list). This audit box writes its own
# SSH ingress inline instead of joining the cross-unit security-rules fan-in.

resource "oci_core_network_security_group" "this" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.display_name}-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# One SSH ingress rule per VPN/office source CIDR (the rule takes a single `source`
# string, so a list fans out one rule per CIDR). var.vpn_source_cidrs is REQUIRED so
# a plan cannot silently produce an unconstrained or empty source.
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