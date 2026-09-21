# Cross-module VPC firewall rules, applied last in the deployment order.
#
# Rules entirely internal to one composition module (e.g. an internal LB to its
# own instances) stay in that module; cross-module connectivity rules (e.g.
# bastion-host to locker SSH) are assembled by the live layer and passed here.
#
# GCP firewall rules are network-wide rather than resource-scoped, matched by
# direction and target/source tags or service accounts. Rules are grouped by
# direction first (ingress_rules / egress_rules), then by logical component
# name, then flattened into the list the upstream submodule expects.

locals {
  ingress_rules_flat = merge([
    for component, group in var.ingress_rules : {
      for rule in group.rules :
      "ingress-${component}-${rule.name}" => merge(rule, {
        name                    = "${local.name_prefix}-${component}-${rule.name}"
        direction               = "INGRESS"
        target_tags             = group.target_tags
        target_service_accounts = group.target_service_accounts
      })
    }
  ]...)

  egress_rules_flat = merge([
    for component, group in var.egress_rules : {
      for rule in group.rules :
      "egress-${component}-${rule.name}" => merge(rule, {
        name                    = "${local.name_prefix}-${component}-${rule.name}"
        direction               = "EGRESS"
        target_tags             = group.target_tags
        target_service_accounts = group.target_service_accounts
      })
    }
  ]...)

  rules_flat = merge(local.ingress_rules_flat, local.egress_rules_flat)
}

module "firewall_rules" {
  source  = "terraform-google-modules/network/google//modules/firewall-rules"
  version = "18.1.2"

  project_id   = var.project_id
  network_name = var.network_name

  rules = values(local.rules_flat)
}
