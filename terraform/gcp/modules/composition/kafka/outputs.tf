output "broker_internal_ips" {
  description = "Static internal IP addresses assigned to broker instances"
  value       = [for addr in google_compute_address.broker : addr.address]
}

output "controller_internal_ips" {
  description = "Static internal IP addresses assigned to controller instances"
  value       = [for addr in google_compute_address.controller : addr.address]
}

output "broker_instance_self_links" {
  description = "Self-links of the broker instances"
  value       = module.broker_instances.instances_self_links
}

output "controller_instance_self_links" {
  description = "Self-links of the controller instances"
  value       = module.controller_instances.instances_self_links
}

output "service_account_email" {
  description = "Email of the shared node service account"
  value       = module.service_account.email
}
