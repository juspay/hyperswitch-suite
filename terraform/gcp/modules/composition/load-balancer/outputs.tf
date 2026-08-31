output "external_ip_address" {
  description = "External IP address of the global HTTP(S) load balancer, if internal = false"
  value       = var.internal ? null : module.external_lb[0].external_ip
}

output "internal_ip_address" {
  description = "IP address of the internal load balancer, if internal = true"
  value       = var.internal ? module.internal_lb[0].ip_address : null
}
