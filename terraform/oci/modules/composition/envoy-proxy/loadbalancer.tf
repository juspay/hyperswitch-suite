# Edge: load balancer, backend sets, listeners, routing policy, WAF.
# Uses OCI's classic Load Balancer (L7, HTTP/HTTPS, TLS termination); the
# Network Load Balancer is L4 with no ssl_configuration and is not used here.

resource "oci_load_balancer_load_balancer" "this" {
  count = var.create_lb ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = local.display_name
  shape          = var.lb_shape
  subnet_ids     = [var.lb_subnet_id]
  is_private     = var.lb_is_private

  # An NSG with rules and no members is silently inert - see network.tf.
  network_security_group_ids = local.lb_nsg_ids

  # A flexible-shape load balancer is billed on the minimum, so this pair is a
  # cost knob as much as a capacity one; the block is required for
  # shape = "flexible" and forbidden otherwise.
  dynamic "shape_details" {
    for_each = var.lb_shape == "flexible" ? [1] : []

    content {
      minimum_bandwidth_in_mbps = var.lb_min_bandwidth_mbps
      maximum_bandwidth_in_mbps = var.lb_max_bandwidth_mbps
    }
  }

  # OCI load balancers get a real IP, so a plain DNS A record at a Reserved
  # Public IP replaces Route 53's ALIAS record; what is lost is
  # evaluate_target_health (needs an oci_dns_steering_policy, not this module's
  # concern).
  dynamic "reserved_ips" {
    for_each = var.lb_reserved_ip_id != null ? [var.lb_reserved_ip_id] : []

    content {
      id = reserved_ips.value
    }
  }

  is_delete_protection_enabled = var.is_delete_protection_enabled

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# One shared set (default), or one per deployment. Backends themselves are NOT
# declared here - oci_core_instance_pool's load_balancers block registers and
# deregisters them as the pool scales, and the backend attribute is read-only.
resource "oci_load_balancer_backend_set" "this" {
  for_each = var.create_lb ? toset(local.backend_set_names) : toset([])

  load_balancer_id = oci_load_balancer_load_balancer.this[0].id
  name             = each.value
  policy           = var.backend_set_policy

  health_checker {
    protocol            = var.health_check.protocol
    port                = local.health_check_port
    url_path            = var.health_check.protocol == "TCP" ? null : var.health_check.url_path
    return_code         = var.health_check.protocol == "TCP" ? null : var.health_check.return_code
    interval_ms         = var.health_check.interval_ms
    timeout_in_millis   = var.health_check.timeout_in_millis
    retries             = var.health_check.retries
    response_body_regex = var.health_check.response_body_regex
  }
}

# OCI's listener has no redirect action of its own, so the redirect is a rule
# set attached to the HTTP listener - same outcome, one extra resource.
resource "oci_load_balancer_rule_set" "https_redirect" {
  count = local.http_redirect_enabled ? 1 : 0

  load_balancer_id = oci_load_balancer_load_balancer.this[0].id
  name             = local.redirect_rule_set_name

  items {
    action = "REDIRECT"

    conditions {
      attribute_name  = "PATH"
      attribute_value = "/"
      operator        = "FORCE_LONGEST_PREFIX_MATCH"
    }

    redirect_uri {
      protocol = "HTTPS"
      host     = "{host}"
      port     = var.lb_https_port
      path     = "{path}"
      query    = "{query}"
    }

    response_code = 301
  }
}

# A routing-policy rule forwards a matched request to exactly ONE named backend
# set - no weighted split across backend sets, no source-IP match dimension.
resource "oci_load_balancer_load_balancer_routing_policy" "this" {
  count = local.routing_policy_enabled ? 1 : 0

  load_balancer_id           = oci_load_balancer_load_balancer.this[0].id
  name                       = local.routing_policy_name
  condition_language_version = "V1"

  dynamic "rules" {
    for_each = var.listener_rules

    content {
      name      = rules.value.name
      condition = local.listener_rule_conditions[rules.value.name]

      actions {
        name             = "FORWARD_TO_BACKENDSET"
        backend_set_name = local.listener_rule_targets[rules.value.name]
      }
    }
  }
}

# Listeners.
resource "oci_load_balancer_listener" "http" {
  count = var.create_lb ? 1 : 0

  load_balancer_id         = oci_load_balancer_load_balancer.this[0].id
  name                     = "${local.name_prefix}-http"
  default_backend_set_name = oci_load_balancer_backend_set.this[local.default_backend_set_name].name
  port                     = var.lb_http_port
  protocol                 = "HTTP"

  rule_set_names      = local.http_redirect_enabled ? [oci_load_balancer_rule_set.https_redirect[0].name] : []
  routing_policy_name = local.routing_policy_enabled && !local.http_redirect_enabled ? oci_load_balancer_load_balancer_routing_policy.this[0].name : null

  connection_configuration {
    idle_timeout_in_seconds = tostring(var.idle_timeout_in_seconds)
  }
}

resource "oci_load_balancer_listener" "https" {
  count = local.https_listener_enabled ? 1 : 0

  load_balancer_id         = oci_load_balancer_load_balancer.this[0].id
  name                     = "${local.name_prefix}-https"
  default_backend_set_name = oci_load_balancer_backend_set.this[local.default_backend_set_name].name
  port                     = var.lb_https_port
  protocol                 = "HTTP"

  routing_policy_name = local.routing_policy_enabled ? oci_load_balancer_load_balancer_routing_policy.this[0].name : null

  # certificate_ids takes a list but accepts a single ID; there is no
  # additional-SNI-certificate equivalent, so var.ssl_certificate_ids is
  # validated to length <= 1. The certificate was NOT publicly issued by OCI -
  # it is IMPORTED from an external ACME client or issued by an internal CA.
  ssl_configuration {
    certificate_ids         = var.ssl_certificate_ids
    cipher_suite_name       = var.ssl_cipher_suite_name
    protocols               = var.ssl_protocols
    verify_peer_certificate = false
  }

  connection_configuration {
    idle_timeout_in_seconds = tostring(var.idle_timeout_in_seconds)
  }
}

# mTLS listener: trusted_certificate_authority_ids is the client-CA trust store
# and verify_depth is the chain-depth control.
resource "oci_load_balancer_listener" "mtls" {
  count = local.mtls_listener_enabled ? 1 : 0

  load_balancer_id         = oci_load_balancer_load_balancer.this[0].id
  name                     = "${local.name_prefix}-mtls"
  default_backend_set_name = oci_load_balancer_backend_set.this[local.default_backend_set_name].name
  port                     = var.mtls_listener.port
  protocol                 = "HTTP"

  ssl_configuration {
    certificate_ids                   = length(var.mtls_listener.certificate_ids) > 0 ? var.mtls_listener.certificate_ids : var.ssl_certificate_ids
    cipher_suite_name                 = var.ssl_cipher_suite_name
    protocols                         = var.ssl_protocols
    verify_peer_certificate           = true
    verify_depth                      = var.mtls_listener.verify_depth
    trusted_certificate_authority_ids = var.mtls_listener.trusted_certificate_authority_ids
  }

  connection_configuration {
    idle_timeout_in_seconds = tostring(var.idle_timeout_in_seconds)
  }
}

# WAF attachment. This module owns the ASSOCIATION only, never the policy
# content. Gap: AWS's enable_waf_fail_open has no counterpart anywhere on this
# resource's schema, so fail-open/fail-closed is whatever OCI's default is.
resource "oci_waf_web_app_firewall" "this" {
  count = local.waf_enabled ? 1 : 0

  compartment_id             = var.compartment_id
  display_name               = "${local.display_name}-waf"
  backend_type               = "LOAD_BALANCER"
  load_balancer_id           = oci_load_balancer_load_balancer.this[0].id
  web_app_firewall_policy_id = var.waf_policy_id

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
