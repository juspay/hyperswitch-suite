# Listeners, and the pieces they reference (split out of main.tf).

# Classic uploaded certificates
# The non-Certificates-Management TLS route. Kept because OCI cannot issue a
# publicly-trusted certificate at all, so any real public certificate arrives as
# PEM from an external ACME client or a purchased CA, and uploading it straight
# here is a legitimate option. Renewal is self-managed on this path with no
# Oracle-side safety net; create_before_destroy is set because replacing a
# certificate a live listener references must not go through a window with no
# certificate at all.
resource "oci_load_balancer_certificate" "this" {
  for_each = var.certificates

  load_balancer_id   = oci_load_balancer_load_balancer.this.id
  certificate_name   = each.key
  public_certificate = each.value.public_certificate
  private_key        = each.value.private_key
  ca_certificate     = each.value.ca_certificate
  passphrase         = each.value.passphrase

  lifecycle {
    create_before_destroy = true
  }
}

# Virtual hostnames
# Host-header routing on a shared listener. UNVERIFIED whether this also lifts
# the one-certificate-per-listener constraint below - nothing assumes it does.
resource "oci_load_balancer_hostname" "this" {
  for_each = var.hostnames

  load_balancer_id = oci_load_balancer_load_balancer.this.id
  name             = each.key
  hostname         = each.value
}

# Rule sets
# VERIFICATION RESULT: the oci_load_balancer_rule_set schema DOES carry a
# redirect action - `action`, `response_code` and a nested `redirect_uri` block -
# so AWS's `redirect` listener default action (bare HTTP -> HTTPS) has a real
# OCI equivalent. It is a separate resource referenced by name from the listener
# rather than an inline default_action, which is why it is PARTIAL.
# STILL A GAP: AWS's `fixed-response` default action (a static 200 "OK" with no
# backend) has no equivalent - the nearest thing is the rejection `status_code`
# on a method filter. Replace a fixed-response listener with a trivial
# always-healthy backend set: one extra backend set, no behaviour change.
resource "oci_load_balancer_rule_set" "this" {
  for_each = var.rule_sets

  load_balancer_id = oci_load_balancer_load_balancer.this.id
  name             = each.key

  dynamic "items" {
    for_each = each.value.items

    content {
      action                         = items.value.action
      allowed_methods                = items.value.allowed_methods
      are_invalid_characters_allowed = items.value.are_invalid_characters_allowed
      description                    = items.value.description
      header                         = items.value.header
      prefix                         = items.value.prefix
      response_code                  = items.value.response_code
      status_code                    = items.value.status_code
      suffix                         = items.value.suffix
      value                          = items.value.value

      dynamic "conditions" {
        for_each = items.value.conditions

        content {
          attribute_name  = conditions.value.attribute_name
          attribute_value = conditions.value.attribute_value
          operator        = conditions.value.operator
        }
      }

      dynamic "redirect_uri" {
        for_each = items.value.redirect_uri != null ? [items.value.redirect_uri] : []

        content {
          host     = redirect_uri.value.host
          path     = redirect_uri.value.path
          port     = redirect_uri.value.port
          protocol = redirect_uri.value.protocol
          query    = redirect_uri.value.query
        }
      }
    }
  }
}

# Listeners
resource "oci_load_balancer_listener" "this" {
  for_each = var.listeners

  load_balancer_id = oci_load_balancer_load_balancer.this.id
  name             = each.key
  port             = each.value.port
  protocol         = each.value.protocol

  # Forwarding to a backend set is an OCI listener's ONLY native default action -
  # there is no default_action_type to choose. A redirect is expressed by
  # attaching a rule set (above); a fixed response has no equivalent.
  # try(): the backend set is normally one this module created, but a listener
  # may point at a set created elsewhere on the same load balancer, so an unknown
  # name falls through to the literal string.
  default_backend_set_name = try(
    oci_load_balancer_backend_set.this[each.value.default_backend_set_name].name,
    each.value.default_backend_set_name,
  )

  # `certificate_ids` is a list in the schema but the provider documents "Currently
  # only a single Id may be passed", so the variable is a scalar and it is wrapped
  # here - making the constraint visible at the call site instead of discovering
  # the limit at apply time. AWS's unlimited additional SNI certs have no counterpart.
  dynamic "ssl_configuration" {
    for_each = (each.value.certificate_ids != null || each.value.certificate_name != null) ? [1] : []

    content {
      certificate_ids = each.value.certificate_ids != null ? [each.value.certificate_ids] : null
      certificate_name = each.value.certificate_name != null ? try(
        oci_load_balancer_certificate.this[each.value.certificate_name].certificate_name,
        each.value.certificate_name,
      ) : null

      protocols                         = each.value.ssl_protocols
      cipher_suite_name                 = each.value.cipher_suite_name
      verify_peer_certificate           = each.value.verify_peer_certificate
      verify_depth                      = each.value.verify_depth
      trusted_certificate_authority_ids = each.value.trusted_certificate_authority_ids
      has_session_resumption            = each.value.has_session_resumption
      server_order_preference           = null
    }
  }

  # Per-listener idle timeout on both clouds; OCI's ceiling is 7200s vs AWS's 4000s.
  dynamic "connection_configuration" {
    for_each = each.value.idle_timeout_in_seconds != null ? [1] : []

    content {
      idle_timeout_in_seconds = each.value.idle_timeout_in_seconds
    }
  }

  hostname_names = [
    for h in each.value.hostname_names :
    try(oci_load_balancer_hostname.this[h].name, h)
  ]

  path_route_set_name = each.value.path_route_set_name
  routing_policy_name = each.value.routing_policy_name

  rule_set_names = [
    for r in each.value.rule_set_names :
    try(oci_load_balancer_rule_set.this[r].name, r)
  ]
}
