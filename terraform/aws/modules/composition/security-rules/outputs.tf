# =========================================================================
# SECURITY RULES OUTPUTS
# =========================================================================

output "locker_ingress_rule_ids" {
  description = "IDs of locker ingress security group rules"
  value       = { for k, v in aws_security_group_rule.locker_ingress : k => v.id }
}

output "locker_egress_rule_ids" {
  description = "IDs of locker egress security group rules"
  value       = { for k, v in aws_security_group_rule.locker_egress : k => v.id }
}

output "nlb_ingress_rule_ids" {
  description = "IDs of NLB ingress security group rules"
  value       = { for k, v in aws_security_group_rule.nlb_ingress : k => v.id }
}

output "nlb_egress_rule_ids" {
  description = "IDs of NLB egress security group rules"
  value       = { for k, v in aws_security_group_rule.nlb_egress : k => v.id }
}

output "squid_ingress_rule_ids" {
  description = "IDs of squid ingress security group rules"
  value       = { for k, v in aws_security_group_rule.squid_ingress : k => v.id }
}

output "squid_egress_rule_ids" {
  description = "IDs of squid egress security group rules"
  value       = { for k, v in aws_security_group_rule.squid_egress : k => v.id }
}

output "envoy_ingress_rule_ids" {
  description = "IDs of Envoy ingress security group rules"
  value       = { for k, v in aws_security_group_rule.envoy_ingress : k => v.id }
}

output "envoy_egress_rule_ids" {
  description = "IDs of Envoy egress security group rules"
  value       = { for k, v in aws_security_group_rule.envoy_egress : k => v.id }
}

output "envoy_lb_ingress_rule_ids" {
  description = "IDs of Envoy LB ingress security group rules"
  value       = { for k, v in aws_security_group_rule.envoy_lb_ingress : k => v.id }
}

output "envoy_lb_egress_rule_ids" {
  description = "IDs of Envoy LB egress security group rules"
  value       = { for k, v in aws_security_group_rule.envoy_lb_egress : k => v.id }
}

output "ext_jump_host_ingress_rule_ids" {
  description = "IDs of external jump host ingress security group rules"
  value       = { for k, v in aws_security_group_rule.ext_jump_host_ingress : k => v.id }
}

output "ext_jump_host_egress_rule_ids" {
  description = "IDs of external jump host egress security group rules"
  value       = { for k, v in aws_security_group_rule.ext_jump_host_egress : k => v.id }
}

output "int_jump_host_ingress_rule_ids" {
  description = "IDs of internal jump host ingress security group rules"
  value       = { for k, v in aws_security_group_rule.int_jump_host_ingress : k => v.id }
}

output "int_jump_host_egress_rule_ids" {
  description = "IDs of internal jump host egress security group rules"
  value       = { for k, v in aws_security_group_rule.int_jump_host_egress : k => v.id }
}

output "rules_summary" {
  description = "Summary of security rules created"
  value = {
    locker_ingress_count = length(var.locker_ingress_rules)
    locker_egress_count  = length(var.locker_egress_rules)
    nlb_ingress_count    = length(var.nlb_ingress_rules)
    nlb_egress_count     = length(var.nlb_egress_rules)
    squid_ingress_count  = length(var.squid_ingress_rules)
    squid_egress_count   = length(var.squid_egress_rules)
    envoy_ingress_count  = length(var.envoy_ingress_rules)
    envoy_egress_count   = length(var.envoy_egress_rules)
    envoy_lb_ingress_count = length(var.envoy_lb_ingress_rules)
    envoy_lb_egress_count  = length(var.envoy_lb_egress_rules)
    ext_jump_host_ingress_count = length(var.ext_jump_host_ingress_rules)
    ext_jump_host_egress_count = length(var.ext_jump_host_egress_rules)
    int_jump_host_ingress_count = length(var.int_jump_host_ingress_rules)
    int_jump_host_egress_count = length(var.int_jump_host_egress_rules)    
    total_rules          = length(var.locker_ingress_rules) + length(var.locker_egress_rules) + length(var.nlb_ingress_rules) + length(var.nlb_egress_rules) + length(var.squid_ingress_rules) + length(var.squid_egress_rules) + length(var.envoy_ingress_rules) + length(var.envoy_egress_rules) + length(var.envoy_lb_ingress_rules) + length(var.envoy_lb_egress_rules) + length(var.ext_jump_host_ingress_rules) + length(var.ext_jump_host_egress_rules) + length(var.int_jump_host_ingress_rules) + length(var.int_jump_host_egress_rules)
  }
}
