# Cross-module VPC firewall rules, applied last in the deployment order.
#
# Rules entirely internal to one composition module (e.g. an internal LB to its
# own instances) stay in that module; cross-module connectivity rules (e.g.
# bastion-host to locker SSH) are assembled by the live layer and passed here.
#
# GCP firewall rules are network-wide rather than resource-scoped, matched by
# direction and target/source tags or service accounts. Rules are grouped by
# logical component name purely for input organization, then flattened into the
# list the upstream submodule expects.

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
