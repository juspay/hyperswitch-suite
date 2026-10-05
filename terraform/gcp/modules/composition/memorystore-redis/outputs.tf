output "instance_id" {
  description = "Fully qualified resource ID of the Redis cluster instance"
  value       = module.redis_cluster.id
}

output "discovery_host" {
  description = "Discovery endpoint IP address clients connect to for cluster topology discovery"
  value       = try(module.redis_cluster.discovery_endpoints[0].address, null)
}

output "discovery_port" {
  description = "Port for the discovery endpoint"
  value       = try(module.redis_cluster.discovery_endpoints[0].port, null)
}

output "discovery_endpoints" {
  description = "Full discovery_endpoints structure for the instance - use this if discovery_host/discovery_port aren't sufficient (e.g. more than one network endpoint)"
  value       = module.redis_cluster.discovery_endpoints
}

output "psc_connections" {
  description = "PSC connections for discovery of the cluster topology and accessing the cluster"
  value       = module.redis_cluster.psc_connections
}
