# OCI Load Balancer (L7), the AWS Application Load Balancer analogue. Strategy:
# DIRECT-RESOURCE (no registry module exists for this service). This is the L7
# half only, exactly like its AWS original. The OCI Network Load Balancer (L4)
# is deliberately NOT built - it would speculatively port a role AWS itself
# never exercises in this stack; its mapping is recorded and ready to reuse.
# Shared decision (defer); Oracle gate not yet consulted.

# What this module does not own:
#   - DNS (zone + records): owned by `composition/dns`; this module only exports
#     `ip_address` for a plain A record.
#   - WAF: oci_waf_web_app_firewall attaches as a sibling resource via
#     `load_balancer_id`; AWS's enable_waf_fail_open bool has no counterpart and
#     is not exposed.
#   - Security rules: the NSG below is created EMPTY.
# Unverified and not papered over: HTTP/2 toggle, and access logging.

# The load balancer's own network access-control object. Created EMPTY on
# purpose: composition/security-rules - the security-last stack phase - writes
# the rules in by reading nsg_id from this module's output. Do not add rules here.
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

# The load balancer
resource "oci_load_balancer_load_balancer" "this" {
  compartment_id = var.compartment_id
  display_name   = local.display_name

  # One regional subnet in this platform; AWS's >=2-subnets-in->=2-AZs
  # requirement has nothing to translate to here.
  subnet_ids = var.subnet_ids

  # Counterpart of AWS's `internal`, with the default inverted to the safe side.
  is_private = var.is_private

  shape = var.shape

  # NEW SURFACE: an ALB has no bandwidth dial, so there is no AWS value to port.
  # The fixed shapes were deprecated in May 2023, so "flexible" + a range is the
  # only current answer, and the maximum is the cost ceiling.
  dynamic "shape_details" {
    for_each = var.shape == "flexible" ? [1] : []

    content {
      minimum_bandwidth_in_mbps = var.minimum_bandwidth_in_mbps
      maximum_bandwidth_in_mbps = var.maximum_bandwidth_in_mbps
    }
  }

  # A stable IP is what makes the `dns` module's plain A record a safe substitute
  # for a Route 53 ALIAS; meaningless on a private LB, so not emitted there.
  dynamic "reserved_ips" {
    for_each = (!var.is_private && var.reserved_ip_id != null) ? [1] : []

    content {
      id = var.reserved_ip_id
    }
  }

  ip_mode                    = var.ip_mode
  network_security_group_ids = local.network_security_group_ids

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

    # AWS's cross-zone load balancing is full-by-absence on OCI: backend sets
    # are not zone-local-preferring, so the practical outcome matches AWS's
    # enabled default with nothing to configure.
    precondition {
      condition     = var.shape != "flexible" || var.minimum_bandwidth_in_mbps <= var.maximum_bandwidth_in_mbps
      error_message = "minimum_bandwidth_in_mbps must not exceed maximum_bandwidth_in_mbps."
    }
  }
}

# Backend sets and backends. OCI's listener REQUIRES default_backend_set_name and
# a backend set is a sub-resource of the load balancer, so the listener-to-backend
# chain AWS split across two modules lives in one here (see variables.tf `backend_sets`).
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
