# =========================================================================
# SECURITY RULES MODULE (OCI)
# =========================================================================
# Cross-module network permissions, applied LAST. Port of
# terraform/aws/modules/composition/security-rules; the same architectural
# role terraform/gcp/modules/composition/firewall-rules plays on GCP.
#
# Design pattern, unchanged from AWS:
#   - Each composition module creates and attaches its OWN NSG(s) and exports
#     the OCIDs (compute: create_vnic_details.nsg_ids; OKE nodes:
#     node_config_details.nsg_ids; LB: network_security_group_ids).
#   - Rules internal to one module stay in that module.
#   - Rules that cross a module boundary are created HERE, on NSGs owned by
#     other Terraform states.
#   - Running last turns the locker<->jump-host cycle into a DAG, which is
#     what lets the other units apply in parallel. Do not distribute these
#     rules back into their units to "simplify".
#
# NSGs ONLY - never oci_core_security_list. Binding decision, see
# docs/multi-cloud-parity/oci/network-security-model.md §5 in
# hyperswitch-infra. Two facts force it: 83% of the live AWS rule set names a
# peer group, and only NSG rules have source_type/destination_type =
# NETWORK_SECURITY_GROUP; and only NSGs have a standalone per-rule resource,
# without which a last-phase module cannot attach a rule to a group it does
# not own (security list rules are inline-only on oci_core_security_list).
#
# STRUCTURALLY CLEANER THAN AWS: oci_core_network_security_group has no
# inline-rule argument at all, so two states can never contend over an NSG's
# rule set. On AWS an aws_security_group with inline ingress blocks would
# fight aws_security_group_rule; here that failure mode does not exist.
# =========================================================================

# Service gateway CIDR labels for this region, resolved at plan time.
# Replaces AWS's hand-maintained per-region s3_prefix_list_id. See locals.tf.
data "oci_core_services" "available" {}

# =========================================================================
# INGRESS
# =========================================================================
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

# =========================================================================
# EGRESS
# =========================================================================
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
