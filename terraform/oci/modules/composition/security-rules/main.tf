locals {
  ingress_rules_flat = merge([
    for group_name, group in var.ingress_rules : {
      for rule in group.rules :
      "${group.nsg_id}_${sha256(jsonencode(rule))}" => merge(rule, { nsg_id = group.nsg_id })
    }
  ]...)

  egress_rules_flat = merge([
    for group_name, group in var.egress_rules : {
      for rule in group.rules :
      "${group.nsg_id}_${sha256(jsonencode(rule))}" => merge(rule, { nsg_id = group.nsg_id })
    }
  ]...)
}

resource "oci_core_network_security_group_security_rule" "ingress" {
  for_each = local.ingress_rules_flat

  network_security_group_id = each.value.nsg_id
  direction                 = "INGRESS"
  protocol                  = each.value.protocol
  description               = each.value.description

  source      = coalesce(each.value.cidr, each.value.source_nsg_id)
  source_type = each.value.source_nsg_id != null ? "NETWORK_SECURITY_GROUP" : "CIDR_BLOCK"

  dynamic "tcp_options" {
    for_each = each.value.protocol == "6" && each.value.port_min != null ? [1] : []
    content {
      destination_port_range {
        min = each.value.port_min
        max = coalesce(each.value.port_max, each.value.port_min)
      }
    }
  }

  dynamic "udp_options" {
    for_each = each.value.protocol == "17" && each.value.port_min != null ? [1] : []
    content {
      destination_port_range {
        min = each.value.port_min
        max = coalesce(each.value.port_max, each.value.port_min)
      }
    }
  }
}

resource "oci_core_network_security_group_security_rule" "egress" {
  for_each = local.egress_rules_flat

  network_security_group_id = each.value.nsg_id
  direction                 = "EGRESS"
  protocol                  = each.value.protocol
  description               = each.value.description

  destination      = coalesce(each.value.cidr, each.value.destination_nsg_id)
  destination_type = each.value.destination_nsg_id != null ? "NETWORK_SECURITY_GROUP" : "CIDR_BLOCK"

  dynamic "tcp_options" {
    for_each = each.value.protocol == "6" && each.value.port_min != null ? [1] : []
    content {
      destination_port_range {
        min = each.value.port_min
        max = coalesce(each.value.port_max, each.value.port_min)
      }
    }
  }

  dynamic "udp_options" {
    for_each = each.value.protocol == "17" && each.value.port_min != null ? [1] : []
    content {
      destination_port_range {
        min = each.value.port_min
        max = coalesce(each.value.port_max, each.value.port_min)
      }
    }
  }
}
