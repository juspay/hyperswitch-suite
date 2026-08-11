output "node_internal_ips" {
  description = "Static internal IP addresses assigned to Cassandra nodes"
  value       = [for addr in google_compute_address.node : addr.address]
}

output "node_instance_self_links" {
  description = "Self-links of the Cassandra node instances"
  value       = module.node_instances.instances_self_links
}

output "service_account_email" {
  description = "Email of the shared node service account"
  value       = module.service_account.email
}

output "seed_discovery_function_uri" {
  description = "HTTPS URI of the seed-discovery function, if enabled"
  value       = var.enable_seed_discovery ? module.seed_discovery[0].function_uri : null
}
