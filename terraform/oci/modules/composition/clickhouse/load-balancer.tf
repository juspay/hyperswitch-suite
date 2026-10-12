# Internal load-balanced HTTP endpoint
# OCI allows a single-subnet Load Balancer (AWS required two AZs, which a
# one-AD region could never satisfy), so load_balancer_subnet_id is singular.
# The Keeper tier is deliberately NOT load-balanced, matching AWS: Keeper is
# addressed directly by peer IP.

resource "oci_load_balancer_load_balancer" "this" {
  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-lb"

  is_private = true

  subnet_ids = [var.load_balancer_subnet_id]

  shape = var.load_balancer_shape

  # Only meaningful for the "flexible" shape.
  dynamic "shape_details" {
    for_each = var.load_balancer_shape == "flexible" ? [1] : []
    content {
      minimum_bandwidth_in_mbps = var.load_balancer_min_bandwidth_in_mbps
      maximum_bandwidth_in_mbps = var.load_balancer_max_bandwidth_in_mbps
    }
  }

  # The load balancer joins the SERVER NSG rather than owning a third one - one
  # fewer object for security-rules to reason about, and the LB's reachability
  # is the same question as the server tier's.
  network_security_group_ids = local.server_nsg_ids

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_load_balancer_backend_set" "servers" {
  load_balancer_id = oci_load_balancer_load_balancer.this.id
  name             = local.backend_set_name
  policy           = var.backend_set_policy

  health_checker {
    protocol          = "HTTP"
    port              = var.clickhouse_port
    url_path          = var.health_check_path
    return_code       = 200
    interval_ms       = var.health_check_interval_ms
    timeout_in_millis = var.health_check_timeout_ms
    retries           = var.health_check_retries
  }
}

# One backend per server. Backends register by the PRIMARY VNIC IP, not the
# reserved secondary one: the reserved IP is a secondary address the guest must
# configure itself, and a health check against an address the guest has not
# brought up yet would fail the backend permanently. Cluster PEERING uses the
# reserved IPs; load-balanced CLIENT traffic uses the primary.
resource "oci_load_balancer_backend" "servers" {
  count = var.server_count

  load_balancer_id = oci_load_balancer_load_balancer.this.id
  backendset_name  = oci_load_balancer_backend_set.servers.name

  ip_address = oci_core_instance.server[count.index].private_ip
  port       = var.clickhouse_port
}

resource "oci_load_balancer_listener" "this" {
  for_each = { for l in local.listeners : l.name => l }

  load_balancer_id         = oci_load_balancer_load_balancer.this.id
  name                     = each.value.name
  default_backend_set_name = oci_load_balancer_backend_set.servers.name

  port     = each.value.port
  protocol = each.value.protocol

  # certificate_ids takes an OCI Certificates OCID.
  dynamic "ssl_configuration" {
    for_each = each.value.certificate_id != null ? [each.value.certificate_id] : []
    content {
      certificate_ids = [ssl_configuration.value]
    }
  }
}
