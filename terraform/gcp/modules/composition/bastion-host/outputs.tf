output "instance_name" {
  description = "Name of the bastion instance"
  value       = module.bastion_host.hostname
}

output "instance_self_link" {
  description = "Self-link of the bastion instance"
  value       = module.bastion_host.self_link
}

output "service_account_email" {
  description = "Email of the bastion's service account"
  value       = module.bastion_host.service_account
}

output "session_log_bucket_name" {
  description = "Name of the session log bucket, if enabled"
  value       = var.enable_session_logging ? module.session_log_bucket[0].name : null
}
