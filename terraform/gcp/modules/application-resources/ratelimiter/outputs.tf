output "service_account_email" {
  description = "Email of the ratelimiter's Google service account"
  value       = module.workload_identity.service_account_email
}

output "k8s_service_account_name" {
  description = "Bound Kubernetes service account name"
  value       = module.workload_identity.k8s_service_account_name
}

output "redis_host" {
  description = "Host/IP of the dedicated Memorystore instance, if created"
  value       = var.create_redis ? module.memorystore[0].host : null
}

output "redis_port" {
  description = "Port of the dedicated Memorystore instance, if created"
  value       = var.create_redis ? module.memorystore[0].port : null
}
