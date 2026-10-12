# =============================================================================
# OCI Load Balancer (L7) - the AWS Application Load Balancer analogue
#
# Strategy: DIRECT-RESOURCE. `search_modules` for "oci load balancer" and "oci
# network load balancer" both return zero results, confirming provider-facts.md
# Tier 1: on OCI, DIRECT-RESOURCE is the default and a registry module is the
# exception - the inverse of the AWS habit.
#
# WHAT THIS MODULE IS, AND IS NOT
#
# It is the L7 half only, exactly like its AWS original. AWS's
# composition/load-balancer hardcodes load_balancer_type = "application" and
# has no NLB toggle anywhere in its 587 lines. The AWS estate does carry NLB
# primitives (base/nlb, base/nlb-listener) and they are wired into ZERO
# composition modules and ZERO live roots - unused library code.
#
# So the OCI Network Load Balancer (oci_network_load_balancer_*) is NOT built
# here. That is a decision, not an omission: building it would be speculatively
# porting a role AWS itself has never exercised. The mapping is verified and
# recorded (load-balancer.md feature 15, edge-tier-strategy.md section 5) and
# is ready to reuse the moment a genuine TCP-passthrough consumer appears.
# ORACLE GATE: load-balancer.md gate item 1 is exactly this build-now-or-defer
# question. NOT YET CONSULTED - the default taken here is the sheet's own
# recommendation (defer), and the gate can still reverse it cheaply because
# nothing depends on the answer yet.
#
# The one thing worth knowing about the NLB if it is ever built: its listener
# schema has NO ssl_configuration field at all. It is pure L3/L4 passthrough,
# stricter than AWS's NLB, which has offered an optional TLS listener type
# since 2019 (also unused by this stack).
#
# WHAT THIS MODULE DELIBERATELY DOES NOT OWN
#
#   - DNS. The AWS module bundles optional aws_route53_zone creation and its
#     own aws_route53_record.alb. Not ported: the `dns` module owns zone and
#     record lifecycle, and this module only exports `ip_address` for it to
#     point a plain A record at. Duplicating zone creation in an edge module
#     is how two modules end up fighting over one zone.
#     load-balancer.md features 12 and 13.
#   - WAF. oci_waf_web_app_firewall attaches to a load balancer as a sibling
#     resource via load_balancer_id + backend_type = "LOAD_BALANCER" - the same
#     shape as aws_wafv2_web_acl_association. All this module owes that owner
#     is the OCID, which `load_balancer_id` exports.
#     GAP, load-balancer.md feature 8, SUBSTITUTE: AWS's enable_waf_fail_open
#     is a boolean ON THE LOAD BALANCER describing what happens when the WAF is
#     unreachable. No fail-open/fail-closed argument exists anywhere on OCI's
#     WAF resource. There is nothing for this module to expose, so it exposes
#     nothing rather than a variable that would silently do nothing.
#   - Security rules. The NSG below is created EMPTY.
#
# UNVERIFIED, and not papered over anywhere in this module:
#   feature 7  HTTP/2 ......... no toggle found on either resource; whether it
#                              is always-on for an HTTP listener or absent was
#                              not resolved. No variable pretends otherwise.
#   feature 10 access logging . no access_logs-equivalent block exists on
#                              oci_load_balancer_load_balancer. OCI's Logging
#                              service may attach at a different layer; not
#                              confirmed, so nothing is wired.
# =============================================================================

# -----------------------------------------------------------------------------
# The load balancer's own network access-control object
# -----------------------------------------------------------------------------
# Created EMPTY on purpose, mirroring composition/database and
# composition/oci-cache-valkey. catalog/units/oci/security-rules - the last
# stack phase - writes the rules in, reading nsg_id from this module's output.
# Do not add rules here.
#
# This is the direct counterpart of the AWS module's dedicated
# aws_security_group plus its ingress/egress rules (feature 2, required), with
# the rules moved to the security-last phase rather than inlined.
resource "oci_core_network_security_group" "this" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.display_name}-nsg"

  freeform_tags = merge(local.common_freeform_tags, { "component" = "load-balancer" })

  lifecycle {
    precondition {
      condition     = var.vcn_id != null
      error_message = "vcn_id is required when create_nsg = true - an NSG is a VCN-scoped object."
    }
  }
}

# -----------------------------------------------------------------------------
# The load balancer
# -----------------------------------------------------------------------------
resource "oci_load_balancer_load_balancer" "this" {
  compartment_id = var.compartment_id
  display_name   = local.display_name

  # One regional subnet in this platform. See variables.tf: AWS's
  # >= 2 subnets in >= 2 AZs requirement has nothing to translate to when the
  # region has one availability domain and the subnets are regional anyway.
  subnet_ids = var.subnet_ids

  # Counterpart of AWS's `internal`, with the default inverted to the safe
  # side - see variables.tf.
  is_private = var.is_private

  shape = var.shape

  # NEW SURFACE: an ALB has no bandwidth dial, so there is no AWS value to
  # port. The fixed shapes were deprecated in May 2023, so `flexible` plus a
  # range is the only current answer, and the maximum is the cost ceiling.
  dynamic "shape_details" {
    for_each = var.shape == "flexible" ? [1] : []

    content {
      minimum_bandwidth_in_mbps = var.minimum_bandwidth_in_mbps
      maximum_bandwidth_in_mbps = var.maximum_bandwidth_in_mbps
    }
  }

  # A stable IP is what makes the `dns` module's plain A record a safe
  # substitute for a Route 53 ALIAS - see variables.tf. Meaningless on a
  # private load balancer, so it is not emitted there.
  dynamic "reserved_ips" {
    for_each = (!var.is_private && var.reserved_ip_id != null) ? [1] : []

    content {
      id = var.reserved_ip_id
    }
  }

  ip_mode                    = var.ip_mode
  network_security_group_ids = local.network_security_group_ids

  # AWS feature 9, FULL.
  is_delete_protection_enabled = var.is_delete_protection_enabled

  is_request_id_enabled = var.is_request_id_enabled
  request_id_header     = var.is_request_id_enabled ? var.request_id_header : null

  freeform_tags = merge(
    local.common_freeform_tags,
    {
      "component" = "load-balancer"
      "scheme"    = var.is_private ? "internal" : "internet-facing"
    }
  )

  lifecycle {
    # OCI caps a VNIC at 5 NSGs and the module's own counts against that.
    precondition {
      condition     = length(local.network_security_group_ids) <= 5
      error_message = "A load balancer VNIC accepts at most 5 NSGs; create_nsg plus network_security_group_ids exceeds that."
    }

    # AWS feature 6, cross-zone load balancing, is FULL-by-absence on OCI:
    # there is no toggle in either direction and backend sets are not
    # documented as zone-local-preferring, so the practical outcome matches
    # AWS's enable_cross_zone_load_balancing = true default with nothing to
    # configure. Noted here rather than as a variable that would do nothing.
    precondition {
      condition     = var.shape != "flexible" || var.minimum_bandwidth_in_mbps <= var.maximum_bandwidth_in_mbps
      error_message = "minimum_bandwidth_in_mbps must not exceed maximum_bandwidth_in_mbps."
    }
  }
}

# -----------------------------------------------------------------------------
# Backend sets and backends
# -----------------------------------------------------------------------------
# NEW to this module - see variables.tf's `backend_sets` description. OCI's
# listener requires default_backend_set_name and a backend set is a sub-resource
# of the load balancer, so the listener-to-backend chain AWS split across two
# modules has to live in one here.
resource "oci_load_balancer_backend_set" "this" {
  for_each = var.backend_sets

  load_balancer_id = oci_load_balancer_load_balancer.this.id
  name             = each.key
  policy           = each.value.policy

  health_checker {
    protocol            = each.value.health_checker.protocol
    port                = each.value.health_checker.port
    url_path            = each.value.health_checker.url_path
    return_code         = each.value.health_checker.return_code
    interval_ms         = each.value.health_checker.interval_ms
    timeout_in_millis   = each.value.health_checker.timeout_in_millis
    retries             = each.value.health_checker.retries
    response_body_regex = each.value.health_checker.response_body_regex
    is_force_plain_text = each.value.health_checker.is_force_plain_text
  }

  dynamic "session_persistence_configuration" {
    for_each = each.value.session_persistence_cookie_name != null ? [1] : []

    content {
      cookie_name = each.value.session_persistence_cookie_name
    }
  }

  # Re-encryption to the backend, distinct from the listener's client-side TLS.
  dynamic "ssl_configuration" {
    for_each = each.value.backend_ssl_certificate_name != null ? [1] : []

    content {
      certificate_name = each.value.backend_ssl_certificate_name
    }
  }
}

# Static backends only. Anything OKE registers through its own
# cloud-controller-manager must NOT also appear here - two registrars on one
# backend set is how it ends up flapping.
resource "oci_load_balancer_backend" "this" {
  for_each = local.flattened_backends

  load_balancer_id = oci_load_balancer_load_balancer.this.id
  backendset_name  = oci_load_balancer_backend_set.this[each.value.backend_set].name

  ip_address      = each.value.ip_address
  port            = each.value.port
  weight          = each.value.weight
  backup          = each.value.backup
  drain           = each.value.drain
  offline         = each.value.offline
  max_connections = each.value.max_connections
}
