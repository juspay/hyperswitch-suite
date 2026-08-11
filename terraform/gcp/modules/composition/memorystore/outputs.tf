output "instance_id" {
  description = "Fully qualified ID of the Memorystore instance"
  value       = module.memorystore.id
}

output "host" {
  description = "Primary endpoint hostname/IP of the instance"
  value       = module.memorystore.host
}

output "port" {
  description = "Port the instance listens on"
  value       = module.memorystore.port
}

output "read_endpoint" {
  description = "Read endpoint (host/port), populated only when read replicas are enabled"
  value       = module.memorystore.read_endpoint
}

output "auth_string" {
  description = "AUTH string for the instance, if auth_enabled is true"
  value       = module.memorystore.auth_string
  sensitive   = true
}
