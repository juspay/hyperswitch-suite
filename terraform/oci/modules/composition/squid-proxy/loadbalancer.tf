# Internal L4 load balancer.
# OCI's Network Load Balancer is L4-only; the ONE `NONE` verdict in this module
# is that it CANNOT terminate TLS - its listener has no ssl_configuration at
# all (AWS's enable_tls_listener has nothing to port to). var.tls_termination_mode
# forces that to be an explicit per-environment decision.

resource "oci_network_load_balancer_network_load_balancer" "this" {
  count = var.create_nlb ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = local.display_name

  # ONE subnet - an OCI NLB is regional, so there is no per-AZ list to supply.
  subnet_id = local.nlb_subnet_id

  is_private = var.nlb_is_private

  # An OCI NLB takes NSGs on its front end, so the health-check rule can be an
  # NSG-to-NSG reference; see network.tf for the part still unconfirmed.
  network_security_group_ids = local.nlb_nsg_ids

  # This is OCI's deeper bump-in-the-wire mode and requires
  # skip_source_dest_check on the backend VNICs, which nothing here sets - see
  # var.nlb_transparent_mode.
  is_preserve_source_destination = var.nlb_transparent_mode

  dynamic "reserved_ips" {
    for_each = var.nlb_reserved_ip_id != null ? [var.nlb_reserved_ip_id] : []

    content {
      id = reserved_ips.value
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_network_load_balancer_backend_set" "this" {
  count = var.create_nlb ? 1 : 0

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.this[0].id
  name                     = local.backend_set_name
  policy                   = var.backend_set_policy

  # Backends are NOT declared here - oci_core_instance_pool.load_balancers
  # registers them as the pool scales (see the open question in compute.tf on
  # whether that works for an NLB). is_preserve_source readdresses at the
  # backend-set level so Squid's access log shows the real client IP, without
  # skip_source_dest_check on the backend VNIC.
  is_preserve_source = var.nlb_preserve_source_destination

  health_checker {
    protocol            = var.health_check.protocol
    port                = local.health_check_port
    url_path            = var.health_check.url_path
    return_code         = var.health_check.return_code
    interval_in_millis  = var.health_check.interval_in_millis
    timeout_in_millis   = var.health_check.timeout_in_millis
    retries             = var.health_check.retries
    response_body_regex = var.health_check.response_body_regex
  }
}

resource "oci_network_load_balancer_listener" "this" {
  count = var.create_nlb ? 1 : 0

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.this[0].id
  name                     = "${local.name_prefix}-tcp"
  default_backend_set_name = oci_network_load_balancer_backend_set.this[0].name
  port                     = var.squid_port

  # TCP, and there is no alternative that terminates TLS on this product; see
  # the file header.
  protocol = "TCP"

  # Squid CONNECT tunnels to slow payment processors are long-lived; the
  # default idle timeout would tear them down mid-transaction.
  tcp_idle_timeout = var.tcp_idle_timeout
}
