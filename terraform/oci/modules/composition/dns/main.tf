# OCI DNS - the AWS Route 53 analogue

# -----------------------------------------------------------------------------
# Zones
# -----------------------------------------------------------------------------
resource "oci_dns_zone" "this" {
  for_each = var.zones

  compartment_id = var.compartment_id
  name           = each.value.name
  zone_type      = "PRIMARY"

  # Private zones live in a PRIVATE-view reference; public ones carry neither.
  view_id = each.value.type == "private" ? local.private_view_id : null
  scope   = each.value.type == "private" ? "PRIVATE" : null

  # DNSSEC only meaningful for public zones - a private view has no parent to publish a DS record to.
  dnssec_state = each.value.type == "public" ? each.value.dnssec_state : null

  freeform_tags = merge(
    local.common_freeform_tags,
    {
      "component" = "dns"
      "zone"      = each.key
      "zone_type" = each.value.type
    }
  )

  lifecycle {
    precondition {
      condition     = each.value.type != "private" || local.private_view_id != null
      error_message = "Zone '${each.key}' is private but no private view is available. This should be unreachable - report it."
    }
  }
}

# -----------------------------------------------------------------------------
# Records
# -----------------------------------------------------------------------------
# No `alias` concept: OCI load balancers get real IPs, so point a plain A record
# (even at a zone apex) at load-balancer's ip_address output. No ALIAS needed.
resource "oci_dns_rrset" "this" {
  for_each = local.flattened_records

  zone_name_or_id = each.value.zone_id
  domain          = each.value.domain
  rtype           = each.value.rtype

  compartment_id = var.compartment_id
  view_id        = each.value.view_id
  scope          = each.value.scope

  # One rrset with N items - OCI groups records of one type at a domain.
  dynamic "items" {
    for_each = toset(each.value.rdata)

    content {
      domain = each.value.domain
      rtype  = each.value.rtype
      ttl    = each.value.ttl
      rdata  = items.value
    }
  }
}
