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
  # AND that view is attached to the VCN's resolver. Both halves are gated on
  # there being at least one private zone at all, so a public-only
  # instantiation creates neither.
  has_private_zones = length(local.private_zones) > 0

  # Gate for resolver.tf. Kept here, next to has_private_zones, because both
  # halves of "is this private zone actually reachable" belong in one place.
  attach_resolver = local.has_private_zones && var.attach_private_views_to_vcn_resolver

  # Either this module owns the private view or the caller supplied a shared
  # one. See resolver.tf for why one view per module beats one view per zone.
  private_view_id = var.private_view_id != null ? var.private_view_id : (
    local.has_private_zones ? oci_dns_view.private[0].id : null
  )

  # ---------------------------------------------------------------------------
  # Records, flattened.
  #
  # Same composite-key shape as the AWS module ("${zone_key}_${record_key}")
  # so records in different zones cannot collide and so the two modules'
  # state addresses read the same way.
  #
  # One real shape difference: OCI's rrset groups every record of one type at
  # one domain into a single resource with an `items` set, where AWS emits one
  # aws_route53_record per entry. No consumer-visible effect - the resolver
  # returns the same answers - but it means `records = [a, b, c]` on one entry
  # becomes three `items`, not three resources.
  # ---------------------------------------------------------------------------
  flattened_records = merge([
    for zone_key, zone in var.zones : {
      for record_key, record in zone.records :
      "${zone_key}_${record_key}" => {
        zone_key = zone_key
        zone_id  = oci_dns_zone.this[zone_key].id
        # "" and "@" both mean the zone apex, as they do on AWS.
        domain = (record.name == "" || record.name == "@") ? zone.name : "${record.name}.${zone.name}"
        rtype  = record.type
        ttl    = record.ttl
        rdata  = record.records
        # Private-zone rrsets must carry the same view/scope as their zone;
        # public ones must carry neither.
        view_id = zone.type == "private" ? local.private_view_id : null
        scope   = zone.type == "private" ? "PRIVATE" : null
      }
    }
  ]...)
}
