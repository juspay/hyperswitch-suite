locals {
  name_prefix  = "${var.environment}-${var.project_name}"
  display_name = coalesce(var.display_name, "${local.name_prefix}-lb")
}

# ============================================================================
# Network Security Group + ingress rules (equivalent of AWS aws_security_group
# + aws_security_group_rule.ingress/egress on the LB)
# ============================================================================
resource "oci_core_network_security_group" "this" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-lb-nsg"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_network_security_group_security_rule" "ingress" {
  for_each = var.ingress_rules

  network_security_group_id = oci_core_network_security_group.this.id
  direction                 = "INGRESS"
  protocol                  = each.value.protocol
  source                    = each.value.cidr_blocks[0]
  source_type               = "CIDR_BLOCK"
  description               = each.value.description

  dynamic "tcp_options" {
    for_each = each.value.protocol == "6" ? [1] : []
    content {
      destination_port_range {
        min = each.value.port
        max = each.value.port
      }
    }
  }
}

# ============================================================================
# Load Balancer (equivalent of AWS aws_lb)
# ============================================================================
resource "oci_load_balancer_load_balancer" "this" {
  count = var.create_lb ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = local.display_name
  shape          = "flexible"
  shape_details {
    minimum_bandwidth_in_mbps = var.min_bandwidth_mbps
    maximum_bandwidth_in_mbps = var.max_bandwidth_mbps
  }

  subnet_ids                 = var.subnet_ids
  is_private                 = var.is_private
  network_security_group_ids = [oci_core_network_security_group.this.id]

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# Backend Sets (equivalent of AWS target groups)
# ============================================================================
resource "oci_load_balancer_backend_set" "this" {
  for_each = var.create_lb ? var.backend_sets : {}

  name             = each.key
  load_balancer_id = oci_load_balancer_load_balancer.this[0].id
  policy           = each.value.policy

  health_checker {
    protocol    = each.value.health_check_protocol
    port        = coalesce(each.value.health_check_port, each.value.port)
    url_path    = each.value.health_check_protocol == "HTTP" ? each.value.health_check_path : null
    return_code = each.value.health_check_protocol == "HTTP" ? each.value.health_check_return_code : null
  }
}

resource "oci_load_balancer_backend" "this" {
  for_each = { for pair in flatten([
    for bs_key, bs in var.backend_sets : [
      for idx, backend in bs.backends : {
        key        = "${bs_key}-${idx}"
        bs_key     = bs_key
        ip_address = backend.ip_address
        port       = backend.port
        weight     = backend.weight
      }
    ]
  ]) : pair.key => pair if var.create_lb }

  load_balancer_id = oci_load_balancer_load_balancer.this[0].id
  backendset_name  = oci_load_balancer_backend_set.this[each.value.bs_key].name
  ip_address       = each.value.ip_address
  port             = each.value.port
  weight           = each.value.weight
}

# ============================================================================
# Listeners (equivalent of AWS aws_lb_listener)
# ============================================================================
resource "oci_load_balancer_listener" "this" {
  for_each = var.create_lb ? var.listeners : {}

  name                     = each.key
  load_balancer_id         = oci_load_balancer_load_balancer.this[0].id
  default_backend_set_name = oci_load_balancer_backend_set.this[each.value.default_backend_set].name
  port                     = each.value.port
  protocol                 = each.value.protocol

  dynamic "ssl_configuration" {
    for_each = each.value.protocol == "HTTPS" ? [1] : []
    content {
      certificate_ids = each.value.certificate_ids
    }
  }
}

# ============================================================================
# DNS Zone + Records (equivalent of AWS aws_route53_zone / aws_route53_record)
# ============================================================================
resource "oci_dns_zone" "this" {
  count = var.create_dns_zone ? 1 : 0

  compartment_id = var.compartment_id
  name           = var.dns_zone_name
  zone_type      = "PRIMARY"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_dns_rrset" "this" {
  for_each = var.create_lb && var.create_dns_zone ? var.dns_records : {}

  zone_name_or_id = oci_dns_zone.this[0].id
  domain          = each.key
  rtype           = each.value.rtype

  items {
    domain = each.key
    rtype  = each.value.rtype
    ttl    = each.value.ttl
    rdata  = oci_load_balancer_load_balancer.this[0].ip_address_details[0].ip_address
  }
}
