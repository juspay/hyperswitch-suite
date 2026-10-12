# =============================================================================
# Internal load-balanced HTTP endpoint (check sheet feature 12, FULL - and 4.5)
# =============================================================================
# The direct structural analogue of the AWS module's internal ALB:
#
#   aws_lb (internal)               -> oci_load_balancer_load_balancer (is_private)
#   aws_lb_target_group             -> oci_load_balancer_backend_set
#   aws_lb_target_group_attachment  -> oci_load_balancer_backend (one per server)
#   aws_lb_listener                 -> oci_load_balancer_listener
#
# ONE PLACE OCI IS LESS CONSTRAINED THAN AWS, and it matters here. AWS's
# alb_subnet_ids carries a hard `length(...) >= 2` validation because an ALB
# requires subnets in two distinct Availability Zones. An OCI Load Balancer is
# compartment-scoped and does not require multiple availability domains - a
# single-subnet deployment is valid. Given ap-mumbai-1 has exactly one AD, the
# AWS rule ported literally could NEVER be satisfied there. This is a removed
# blocker, not a convenience.
#
# The Keeper tier is deliberately NOT load-balanced, matching AWS: Keeper is
# addressed directly by peer IP.

resource "oci_load_balancer_load_balancer" "this" {
  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-lb"

  # Internal, matching aws_lb `internal = true`.
  is_private = true

  # Singular. See var.load_balancer_subnet_id.
  subnet_ids = [var.load_balancer_subnet_id]

  shape = var.load_balancer_shape

  # No AWS counterpart: an ALB has no customer-set bandwidth floor or ceiling.
  # Only meaningful for the "flexible" shape.
  dynamic "shape_details" {
    for_each = var.load_balancer_shape == "flexible" ? [1] : []
    content {
      minimum_bandwidth_in_mbps = var.load_balancer_min_bandwidth_in_mbps
      maximum_bandwidth_in_mbps = var.load_balancer_max_bandwidth_in_mbps
    }
  }

  # The AWS module creates a dedicated ALB security group. Here the load balancer
  # joins the SERVER NSG rather than owning a third one - one fewer object for
  # composition/security-rules to reason about, and the LB's reachability is the
  # same question as the server tier's.
  network_security_group_ids = local.server_nsg_ids

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_load_balancer_backend_set" "servers" {
  load_balancer_id = oci_load_balancer_load_balancer.this.id
  name             = local.backend_set_name
  policy           = var.backend_set_policy

  # AWS's target group health check on /ping, ported argument for argument.
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

# One backend per server, the aws_lb_target_group_attachment equivalent.
#
# NOTE the addressing choice: backends register by IP ADDRESS, and the address
# used is the instance's primary VNIC IP, not its reserved secondary IP. That is
# deliberate - the reserved IP is a secondary address the guest must configure
# itself, and a load balancer health check against an address the guest has not
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

  # certificate_ids takes an OCI Certificates OCID where AWS took an ACM
  # certificate_arn. Same role, different identifier namespace.
  dynamic "ssl_configuration" {
    for_each = each.value.certificate_id != null ? [each.value.certificate_id] : []
    content {
      certificate_ids = [ssl_configuration.value]
    }
  }
}
