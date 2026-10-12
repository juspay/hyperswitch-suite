# =============================================================================
# OCI DNS - the AWS Route 53 analogue
#
# Strategy: DIRECT-RESOURCE. `search_modules` for "oci dns" returns exactly one
# module (CyberCoreSystems/dns-zone/oci v1.0.1, 5 downloads, unverified), which
# fails the framework.md section 3 bar of ">50k downloads or verified" by four
# orders of magnitude. The AWS original was already DIRECT-RESOURCE-shaped, so
# this is one of the few modules where the port changes almost nothing about
# the strategy - only about the resource graph.
#
# What survives intact (route53.md): public zones (feature 1, FULL), standard
# records (3, FULL), the output surface (14, FULL).
#
# What does not, all commented at the point of divergence:
#   feature 2  private zone + VCN visibility ... PARTIAL - resolver.tf
#   feature 4  alias record at the apex ........ PARTIAL - below
#   features 5/6/7/10 routing policies ......... PARTIAL - variables.tf
#   features 8/9 geoproximity, latency ......... NONE    - variables.tf
#   features 11/12 multivalue, health checks ... SUBSTITUTE - variables.tf
#   feature 13 reusable delegation set ......... NONE    - variables.tf
# =============================================================================

# -----------------------------------------------------------------------------
# Zones
# -----------------------------------------------------------------------------
resource "oci_dns_zone" "this" {
  for_each = var.zones

  compartment_id = var.compartment_id
  name           = each.value.name
  zone_type      = "PRIMARY"

  # The private/public split. On AWS this is the presence or absence of an
  # inline `vpc {}` block on the same resource. On OCI it is a view reference
  # plus a scope, and the view is a separate object with its own lifecycle -
  # route53.md feature 2, PARTIAL. See resolver.tf for the third object.
  view_id = each.value.type == "private" ? local.private_view_id : null
  scope   = each.value.type == "private" ? "PRIVATE" : null

  # No AWS counterpart in the source module; additive, not a port.
  # Only meaningful for public zones - a private view has no parent zone to
  # publish a DS record to.
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
# route53.md feature 4, PARTIAL, and the reason there is no `alias` concept
# anywhere in this module:
#
# Route 53's ALIAS record exists because an ALB/ELB has only a DNS hostname,
# never a fixed IP, and CNAME is illegal at a zone apex. OCI's Load Balancer
# and Network Load Balancer are both assigned REAL IP addresses, and a Reserved
# Public IP keeps that address stable across the load balancer being recreated.
# So the problem ALIAS solves largely does not exist here: point a plain A
# record at composition/load-balancer's `ip_address` output, at the apex, done.
# Oracle's own documentation recommends exactly this over the nonstandard ALIAS
# record type.
#
# What is genuinely lost is `evaluate_target_health` - one Route 53 boolean
# that stops answering with an unhealthy target. The OCI equivalent is a full
# oci_dns_steering_policy carrying a HEALTH rule plus an OCI Health Checks
# monitor: three resources for what was a flag. Not built here (see
# variables.tf); build it if and when an active/passive DNS failover design
# actually exists.
resource "oci_dns_rrset" "this" {
  for_each = local.flattened_records

  zone_name_or_id = each.value.zone_id
  domain          = each.value.domain
  rtype           = each.value.rtype

  compartment_id = var.compartment_id
  view_id        = each.value.view_id
  scope          = each.value.scope

  # One rrset, N items. AWS emits one resource per record; OCI groups every
  # record of a type at a domain into this set. Same answers on the wire.
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
