output "internal_lb_ip_address" {
  description = "IP address of the internal load balancer in front of the Squid fleet"
  value       = module.internal_lb.ip_address
}

output "instance_group" {
  description = "Self-link of the proxy fleet's managed instance group"
  value       = module.proxy_mig.instance_group
}

output "config_bucket_name" {
  description = "Name of the config bucket"
  value       = module.config_bucket.name
}

output "log_bucket_name" {
  description = "Name of the access-log bucket"
  value       = module.log_bucket.name
}

output "service_account_email" {
  description = "Email of the proxy fleet's service account"
  value       = module.service_account.email
}
