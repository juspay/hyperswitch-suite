# =========================================================================
# FIREWALL RULES MODULE
# =========================================================================
# GCP equivalent of composition/security-rules. Manages cross-module VPC
# firewall rules.
#
# Design Pattern (same as the AWS security-rules module):
#   - Per-service firewall rules that are entirely internal to one
#     composition module (e.g. an internal LB -> its own instances) stay in
#     that composition module.
#   - Cross-module connectivity rules (e.g. bastion-host -> locker SSH) are
#     assembled by the live layer and passed into this module, which is
#     applied last in the deployment order.
#
# Unlike AWS security groups, GCP firewall rules are not scoped to a
# resource - they are network-wide and matched via direction, target/source
# tags, or target/source service accounts. So there is no per-"sg_id"
# grouping on GCP; instead rules are grouped by logical component name
# purely for input organization, then flattened into the list the
# `firewall-rules` submodule expects.
# =========================================================================

locals {
  rules_flat = merge([
    for component, group in var.rules : {
      for rule in group.rules :
      "${component}-${rule.name}" => merge(rule, { name = "${local.name_prefix}-${component}-${rule.name}" })
    }
  ]...)
}

module "firewall_rules" {
  source  = "terraform-google-modules/network/google//modules/firewall-rules"
  version = "18.1.2"

  project_id   = var.project_id
  network_name = var.network_name

  rules = values(local.rules_flat)
}
