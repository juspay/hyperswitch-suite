# ============================================================================
# Locker Outputs
# ============================================================================

# Instance Information
output "locker_instance_ids" {
  description = "List of IDs of the locker instances"
  value       = module.locker.instance_ids
}

output "locker_private_ips" {
  description = "List of private IP addresses of the locker instances"
  value       = module.locker.instance_private_ips
}

output "locker_instance_arns" {
  description = "List of ARNs of the locker instances"
  value       = module.locker.instance_arns
}

output "locker_port" {
  description = "Port number used for the locker service"
  value       = module.locker.locker_port
}

# Network Configuration
output "locker_subnet_id" {
  description = "Subnet ID where the locker instance is deployed"
  value       = module.locker.subnet_id
}

# Security Configuration
output "locker_security_group_id" {
  description = "Security group ID of the locker instance"
  value       = module.locker.security_group_id
}

output "locker_nlb_security_group_id" {
  description = "Security group ID of the locker NLB"
  value       = module.locker.nlb_security_group_id
}

output "locker_key_name" {
  description = "SSH key pair name used for the locker instance"
  value       = module.locker.key_name
}

output "locker_ssh_private_key_ssm_parameter" {
  description = "SSM Parameter Store path where the auto-generated SSH private key is stored (null if key was not auto-generated)"
  value       = module.locker.ssh_private_key_ssm_parameter
}

# Network Load Balancer
output "locker_nlb_dns" {
  description = "DNS name of the Network Load Balancer for locker"
  value       = module.locker.nlb_dns_name
}

output "locker_nlb_endpoint" {
  description = "HTTPS endpoint for accessing locker via NLB"
  value       = "https://${module.locker.nlb_dns_name}"
}

# NLB Listeners Information
output "locker_nlb_listener_arns" {
  description = "ARNs of the NLB listeners"
  value       = module.locker.nlb_listener_arns
}

output "locker_nlb_listener_details" {
  description = "Details of the NLB listeners (port and protocol)"
  value       = module.locker.nlb_listener_details
}
