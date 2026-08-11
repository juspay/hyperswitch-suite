# ============================================================================
# OCI DNS Zones - equivalent of the AWS `route53` composition module
# (aws_route53_zone). Raw oci provider resource - no verified registry
# module exists for OCI DNS.
# ============================================================================
resource "oci_dns_zone" "this" {
  for_each = var.zones

  compartment_id = var.compartment_id
  name           = each.value.name
  zone_type      = each.value.zone_type
  scope          = each.value.scope

  freeform_tags = merge(var.freeform_tags, each.value.tags)
  defined_tags  = var.defined_tags
}

# ============================================================================
# OCI DNS RRSets - equivalent of the AWS aws_route53_record resources
# (OCI groups records by domain+rtype into a single RRSet, unlike AWS's
# one-resource-per-record model)
# ============================================================================
resource "oci_dns_rrset" "this" {
  for_each = merge([
    for zone_key, zone in var.zones : {
      for record_key, record in zone.records : "${zone_key}_${record_key}" => merge(record, {
        zone_key = zone_key
        domain   = record_key
      })
    }
  ]...)

  zone_name_or_id = oci_dns_zone.this[each.value.zone_key].id
  domain          = each.value.domain
  rtype           = each.value.rtype

  dynamic "items" {
    for_each = each.value.rdata
    content {
      domain = each.value.domain
      rtype  = each.value.rtype
      ttl    = each.value.ttl
      rdata  = items.value
    }
  }
}
