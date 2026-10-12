# =============================================================================
# Edge: load balancer, backend sets, listeners, routing policy, WAF
# =============================================================================
# OCI's classic Load Balancer (LBaaS) is the ALB counterpart - L7, HTTP/HTTPS
# listeners, ssl_configuration for TLS termination, host/path routing policies.
# The Network Load Balancer is the L4 product and has no ssl_configuration at
# all; it is not used here. See oci/edge-tier-strategy.md section 5.

resource "oci_load_balancer_load_balancer" "this" {
  count = var.create_lb ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = local.display_name
  shape          = var.lb_shape
  subnet_ids     = [var.lb_subnet_id]
  is_private     = var.lb_is_private

  # Membership is declared here, on the consumer, not on the NSG. An NSG with
  # rules and no members is silently inert - see network.tf.
  network_security_group_ids = local.lb_nsg_ids

  # A flexible-shape load balancer is billed on the minimum, so this pair is a
  # cost knob as much as a capacity one. The shape_details block is required
  # for shape = "flexible" and forbidden otherwise.
  dynamic "shape_details" {
    for_each = var.lb_shape == "flexible" ? [1] : []

    content {
      minimum_bandwidth_in_mbps = var.lb_min_bandwidth_mbps
      maximum_bandwidth_in_mbps = var.lb_max_bandwidth_mbps
    }
  }

  # OCI load balancers get a real IP, so a plain DNS A record at a Reserved
  # Public IP replaces Route 53's ALIAS record entirely - the apex-CNAME
  # problem that ALIAS exists to solve does not arise here. What is lost is
  # ALIAS's evaluate_target_health, which on OCI needs a full
  # oci_dns_steering_policy plus a Health Checks monitor. Not this module's
  # concern; recorded so nobody looks for the missing flag.
  # oci/edge-tier-strategy.md section 3.
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

# -----------------------------------------------------------------------------
# Backend set(s)
# -----------------------------------------------------------------------------
# One shared set (default), or one per deployment - see var.traffic_split_mode.
# Backends themselves are NOT declared here: oci_core_instance_pool's
# load_balancers block registers and deregisters them as the pool scales, and
# oci_load_balancer_backend_set.backend is read-only for exactly that reason.
resource "oci_load_balancer_backend_set" "this" {
  for_each = var.create_lb ? toset(local.backend_set_names) : toset([])

  load_balancer_id = oci_load_balancer_load_balancer.this[0].id
  name             = each.value
  policy           = var.backend_set_policy

  # Direct structural match for the AWS target group's health_check block.
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

# -----------------------------------------------------------------------------
# HTTP -> HTTPS redirect
# -----------------------------------------------------------------------------
# OCI's listener has no redirect action of its own the way AWS's
# aws_lb_listener default_action { type = "redirect" } does, so the redirect is
# a rule set attached to the HTTP listener. Same outcome, one extra resource -
# the redirect capability itself is FULL parity.
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

# -----------------------------------------------------------------------------
# Routing policy (PARTIAL - check sheet feature 6)
# -----------------------------------------------------------------------------
# A routing-policy rule forwards a matched request to exactly ONE named backend
# set. There is no weighted split across backend sets here and no source-IP
# match dimension - see var.listener_rules for both, and locals.tf for the
# condition generator and its raw_condition escape hatch.
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

# -----------------------------------------------------------------------------
# Listeners
# -----------------------------------------------------------------------------
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

  # PARTIAL - check sheet feature 4. certificate_ids takes a list but the
  # schema's own text says "currently only a single Id may be passed", and
  # there is no aws_lb_listener_certificate equivalent for additional SNI
  # certificates. var.ssl_certificate_ids is validated to length <= 1 so this
  # fails at plan time rather than at apply time. The mitigation is one
  # wildcard/SAN certificate covering every served hostname.
  #
  # Whichever certificate lands here was NOT issued by OCI as a publicly
  # trusted cert - OCI's Certificates Management cannot do that. It is either
  # IMPORTED from an externally-run ACME client or issued by an internal CA.
  # oci/edge-tier-strategy.md section 4.
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

# mTLS listener (FULL - check sheet feature 5).
# trusted_certificate_authority_ids is the OCI analogue of ACM's trust-store
# ARN and verify_depth matches AWS's chain-depth control.
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

# -----------------------------------------------------------------------------
# WAF attachment (FULL - check sheet feature 7)
# -----------------------------------------------------------------------------
# A 1:1 structural match for aws_wafv2_web_acl_association: this module owns
# the ASSOCIATION only, never the policy content, exactly as the AWS module
# takes waf_web_acl_arn as an input.
#
# oci_waf_web_app_firewall is the current-generation WAF service, distinct from
# the older oci_waas_* family. It attaches only to the LBaaS load balancer,
# never to the Network Load Balancer - immaterial here, material for
# squid-proxy.
#
# Gap with no field to set: AWS's enable_waf_fail_open has no counterpart
# anywhere on this resource's schema, so fail-open/fail-closed behaviour is
# whatever OCI's service default is and cannot be declared here.
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
