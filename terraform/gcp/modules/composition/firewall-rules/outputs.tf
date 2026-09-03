# FIREWALL RULES OUTPUTS

output "firewall_rules" {
  description = "Map of created firewall rule self-links, keyed by rule name"
  value       = module.firewall_rules.firewall_rules
}

output "firewall_rules_ingress_egress" {
  description = "Firewall rule self-links split into ingress_rules / egress_rules lists"
  value       = module.firewall_rules.firewall_rules_ingress_egress
}

output "rules_summary" {
  description = "Summary of firewall rules created"
  value = {
    total_rules = length(local.rules_flat)
    by_component = {
      for component, group in var.rules :
      component => length(group.rules)
    }
  }
}
