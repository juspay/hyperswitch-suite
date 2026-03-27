# ============================================================================
# Jump Host Outputs
# ============================================================================

output "jump_instance_id" {
  description = "The ID of the jump host instance"
  value       = module.jump_host.external_jump_instance_id
}

output "jump_private_ip" {
  description = "The private IP address of the jump host"
  value       = module.jump_host.external_jump_private_ip
}

output "jump_public_ip" {
  description = "The public IP address of the jump host"
  value       = module.jump_host.external_jump_public_ip
}

output "jump_ssm_command" {
  description = "AWS CLI command to connect to jump host via Session Manager"
  value       = module.jump_host.jump_ssm_command
}

output "iam_role_arn" {
  description = "The ARN of the IAM role for jump host"
  value       = module.jump_host.iam_role_arn
}

output "security_group_id" {
  description = "The ID of the jump host security group"
  value       = module.jump_host.security_group_id
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = module.jump_host.cloudwatch_log_group
}

output "migration_mode_status" {
  description = "Current migration mode status"
  value       = module.jump_host.migration_mode_status
}

output "fleet_manager_status" {
  description = "Fleet Manager user management status"
  value       = module.jump_host.fleet_manager_status
}

output "connection_guide" {
  description = "Guide for connecting to jump host"
  value       = module.jump_host.connection_guide
}
