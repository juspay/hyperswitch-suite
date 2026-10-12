###############################################################################
# Named shared route tables
#
# The routing policy, not the subnets, is where the PCI-relevant control lives
# in the AWS module, and it ports across intact: 12 named tables (13 until
# correction C7 dropped common-internet-osn), each tier associated with the one
# that encodes its egress policy. See the catalogue in
# locals.tf for the AWS name each one replaces and for the feature-12 control
# on the oke-nodes table (no 0.0.0.0/0 rule at all).
#
# Limits: 300 route tables per VCN, 200 rules each - comfortable headroom.
###############################################################################

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
