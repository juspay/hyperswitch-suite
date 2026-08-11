output "keeper_internal_ips" {
  description = "Static internal IP addresses assigned to keeper instances"
  value       = [for addr in google_compute_address.keeper : addr.address]
}

output "server_instance_self_links" {
  description = "Self-links of the ClickHouse server instances"
  value       = module.server_group.instances_self_links
}

output "keeper_instance_self_links" {
  description = "Self-links of the ClickHouse keeper instances"
  value       = module.keeper_instances.instances_self_links
}

output "internal_lb_ip_address" {
  description = "IP address of the internal load balancer in front of the server tier"
  value       = module.internal_lb.ip_address
}

output "service_account_email" {
  description = "Email of the shared node service account"
  value       = module.service_account.email
}
