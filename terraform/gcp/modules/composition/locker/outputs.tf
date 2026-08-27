output "locker_instance_self_links" {
  description = "Self-links of the locker instances"
  value       = module.locker_group.instances_self_links
}

output "internal_lb_ip_address" {
  description = "IP address of the internal load balancer in front of the locker fleet"
  value       = module.internal_lb.ip_address
}

output "kms_key_name" {
  description = "Self-link of the KMS key used for the locker's disk and database encryption"
  value       = module.kms.keys["locker"]
}

output "service_account_email" {
  description = "Email of the shared locker node service account"
  value       = module.service_account.email
}

output "database_instance_connection_name" {
  description = "Cloud SQL Auth Proxy connection name for the locker database, if created"
  value       = var.create_locker_database ? module.database[0].instance_connection_name : null
}
