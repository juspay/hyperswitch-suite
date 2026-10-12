# Named shared route tables - 12 of them (13 until common-internet-osn was
# dropped), carrying the routing policy each tier associates to. This is where
# the PCI-relevant control lives: the oke-nodes table has no 0.0.0.0/0 rule.
# Limits: 300 route tables per VCN, 200 rules each.

resource "oci_core_route_table" "this" {
  for_each = local.route_tables

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_prefix}-${each.key}"

  dynamic "route_rules" {
    for_each = local.route_table_rules[each.key]
    content {
      destination       = route_rules.value.destination
      destination_type  = route_rules.value.destination_type
      network_entity_id = route_rules.value.network_entity_id
      description       = route_rules.value.description
    }
  }

  freeform_tags = merge(
    local.common_freeform_tags,
    { "policy" = each.value.description },
    contains(["locker-db", "locker-server-osn"], each.key) ? { "Compliance" = "PCI-DSS" } : {}
  )
  defined_tags = var.defined_tags
}
