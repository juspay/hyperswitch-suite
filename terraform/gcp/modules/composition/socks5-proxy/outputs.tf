output "internal_lb_ip_address" {
  description = "Internal address the SOCKS5 proxy is reachable on. This is what email.smtp.socks5.host should be set to."
  value       = module.internal_lb.ip_address
}

output "socks5_port" {
  description = "Port the proxy listens on - email.smtp.socks5.port."
  value       = var.socks5_port
}

output "instance_group" {
  description = "Self-link of the MIG's instance group."
  value       = module.proxy_mig.instance_group
}

output "config_bucket_name" {
  description = "Bucket the instances fetch danted.conf from at boot."
  value       = module.config_bucket.name
}

output "log_bucket_name" {
  description = "Bucket holding shipped proxy logs."
  value       = module.log_bucket.name
}

output "service_account_email" {
  description = "Service account the proxy instances run as."
  value       = module.service_account.email
}
