output "node_instance_self_links" {
  description = "Self-links of the OpenSearch node instances"
  value       = module.node_group.instances_self_links
}

output "internal_lb_ip_address" {
  description = "IP address of the internal load balancer in front of the node fleet"
  value       = module.internal_lb.ip_address
}

output "service_account_email" {
  description = "Email of the shared node service account"
  value       = module.service_account.email
}
