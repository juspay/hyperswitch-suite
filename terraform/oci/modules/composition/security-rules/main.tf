# Cross-module NSG security rules, created last so cross-unit grants turn the
# locker<->jump-host cycle into a DAG and the other units apply in parallel.
# NSGs only, never security lists.
data "oci_core_services" "available" {}

# INGRESS
resource "oci_core_network_security_group_security_rule" "ingress" {
  for_each = local.ingress_rules_flat

  network_security_group_id = each.value.nsg_id
  direction                 = "INGRESS"
  protocol                  = each.value.protocol
  description               = each.value.description

  source_type = each.value.target_type
  source      = each.value.target

  # Explicit and NOT exposed as a live-layer input, deliberately. A stateless
  # rule silently takes precedence over an overlapping stateful one and the
  # connection stops being tracked, which breaks return traffic in a way that
  # is very hard to diagnose. false matches AWS security-group semantics
  # exactly, which is what the ported rule set assumes.
  stateless = false

  # OCI expresses ports inside a per-protocol options block, and omitting the
  # block means "all ports" - which is also how AWS's from_port = 0 /
  # to_port = 65535 sentinel has to be expressed, because OCI rejects port 0.
  dynamic "tcp_options" {
    for_each = each.value.protocol == "6" && !each.value.all_ports ? [1] : []
    content {
      destination_port_range {
        min = each.value.from_port
        max = each.value.to_port
      }
    }
  }

  dynamic "udp_options" {
    for_each = each.value.protocol == "17" && !each.value.all_ports ? [1] : []
    content {
      destination_port_range {
        min = each.value.from_port
        max = each.value.to_port
      }
    }
  }

  # AWS encodes ICMP as type in from_port and code in to_port; to_port = -1
  # means "all codes", which OCI expresses by omitting `code`.
  dynamic "icmp_options" {
    for_each = contains(["1", "58"], each.value.protocol) ? [1] : []
    content {
      type = each.value.from_port
      code = each.value.to_port >= 0 ? each.value.to_port : null
    }
  }
}

# EGRESS
resource "oci_core_network_security_group_security_rule" "egress" {
  for_each = local.egress_rules_flat

  network_security_group_id = each.value.nsg_id
  direction                 = "EGRESS"
  protocol                  = each.value.protocol
  description               = each.value.description

  destination_type = each.value.target_type
  destination      = each.value.target

  stateless = false

  dynamic "tcp_options" {
    for_each = each.value.protocol == "6" && !each.value.all_ports ? [1] : []
    content {
      destination_port_range {
        min = each.value.from_port
        max = each.value.to_port
      }
    }
  }

  dynamic "udp_options" {
    for_each = each.value.protocol == "17" && !each.value.all_ports ? [1] : []
    content {
      destination_port_range {
        min = each.value.from_port
        max = each.value.to_port
      }
    }
  }

  dynamic "icmp_options" {
    for_each = contains(["1", "58"], each.value.protocol) ? [1] : []
    content {
      type = each.value.from_port
      code = each.value.to_port >= 0 ? each.value.to_port : null
    }
  }
}
