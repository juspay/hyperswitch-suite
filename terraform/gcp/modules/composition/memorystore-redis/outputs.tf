output "instance_id" {
  description = "Fully qualified resource ID of the Redis instance (projects/<project>/locations/<region>/instances/<name>)"
  value       = module.redis.id
}

output "host" {
  description = "IP address of the primary endpoint. A plain (non-cluster) Redis endpoint: clients connect here directly, there is no discovery step. After a failover this address does not change"
  value       = module.redis.host
}

output "port" {
  description = "Port of the primary endpoint"
  value       = module.redis.port
}

output "read_endpoint" {
  description = "IP address of the read-only endpoint, populated only when read replicas are enabled (read_replica_count > 0)"
  value       = module.redis.read_endpoint
}

output "current_location_id" {
  description = "The zone the primary currently runs in. Changes after a failover"
  value       = module.redis.current_location_id
}

output "auth_string" {
  description = "AUTH password, only when auth_enabled = true"
  value       = module.redis.auth_string
  sensitive   = true
}
