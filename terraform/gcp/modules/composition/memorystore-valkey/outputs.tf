output "instance_id" {
  description = "Fully qualified resource ID of the Valkey cluster instance"
  value       = module.valkey_cluster.id
}

output "discovery_host" {
  description = "Discovery endpoint IP address clients connect to for cluster topology discovery (analogous to classic Memorystore's host output). Derived from local.discovery_connection, not the submodule's own psc_auto_connection output - see locals.tf for why."
  value       = try(local.discovery_connection.ip_address, null)
}

output "discovery_port" {
  description = "Port for the discovery endpoint"
  value       = try(local.discovery_connection.port, null)
}

output "endpoints" {
  description = "Full endpoints structure for the instance (all connections, all endpoint types) - use this if discovery_host/discovery_port aren't sufficient"
  value       = module.valkey_cluster.endpoints
}
