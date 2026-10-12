locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_freeform_tags = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "managed_by"  = "terraform"
    },
    var.freeform_tags
  )

  public_zones = {
    for k, z in var.zones : k => z if z.type == "public"
  }

  private_zones = {
    for k, z in var.zones : k => z if z.type == "private"
  }

  # A private zone is invisible inside the VCN unless a PRIVATE view holds it
  # AND that view is attached to the VCN's resolver. Both gated on having any private zone.
  has_private_zones = length(local.private_zones) > 0

  # Gate for resolver.tf.
  attach_resolver = local.has_private_zones && var.attach_private_views_to_vcn_resolver

  # Either this module owns the private view or the caller supplied a shared one.
  private_view_id = var.private_view_id != null ? var.private_view_id : (
    local.has_private_zones ? oci_dns_view.private[0].id : null
  )

  # Records, flattened to a "<zone_key>_<record_key>" composite key.
  flattened_records = merge([
    for zone_key, zone in var.zones : {
      for record_key, record in zone.records :
      "${zone_key}_${record_key}" => {
        zone_key = zone_key
        zone_id  = oci_dns_zone.this[zone_key].id
        # "" and "@" both mean the zone apex.
        domain = (record.name == "" || record.name == "@") ? zone.name : "${record.name}.${zone.name}"
        rtype  = record.type
        ttl    = record.ttl
        rdata  = record.records
        # Private-zone rrsets carry the same view/scope as their zone; public ones neither.
        view_id = zone.type == "private" ? local.private_view_id : null
        scope   = zone.type == "private" ? "PRIVATE" : null
      }
    }
  ]...)
}
