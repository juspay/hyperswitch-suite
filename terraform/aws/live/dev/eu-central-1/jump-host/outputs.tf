# ============================================================================
# Jump Host Outputs
# ============================================================================

# External Jump Host
output "external_jump_instance_id" {
  description = "The ID of the external jump host instance"
  value       = module.jump_host.external_jump_instance_id
}

output "external_jump_private_ip" {
  description = "The private IP address of the external jump host"
  value       = module.jump_host.external_jump_private_ip
}

output "external_jump_public_ip" {
  description = "The public IP address of the external jump host"
  value       = module.jump_host.external_jump_public_ip
}

output "external_jump_ssm_command" {
  description = "AWS CLI command to connect to external jump host via Session Manager"
  value       = module.jump_host.external_jump_ssm_command
}

# Internal Jump Host
output "internal_jump_instance_id" {
  description = "The ID of the internal jump host instance"
  value       = module.jump_host.internal_jump_instance_id
}

output "internal_jump_private_ip" {
  description = "The private IP address of the internal jump host"
  value       = module.jump_host.internal_jump_private_ip
}

output "internal_jump_ssm_command" {
  description = "AWS CLI command to connect to internal jump host via Session Manager"
  value       = module.jump_host.internal_jump_ssm_command
}

# IAM Roles
output "external_iam_role_arn" {
  description = "The ARN of the IAM role for external jump host"
  value       = module.jump_host.external_iam_role_arn
}

output "internal_iam_role_arn" {
  description = "The ARN of the IAM role for internal jump host"
  value       = module.jump_host.internal_iam_role_arn
}

# SSH Key
output "internal_jump_ssh_key_ssm_path" {
  description = "SSM Parameter Store path for internal jump SSH private key"
  value       = module.jump_host.internal_jump_ssh_key_ssm_path
}

output "internal_jump_ssh_key_retrieval_command" {
  description = "Command to retrieve internal jump SSH private key"
  value       = module.jump_host.internal_jump_ssh_key_retrieval_command
}

# Security Groups
output "external_security_group_id" {
  description = "The ID of the external jump host security group"
  value       = module.jump_host.external_security_group_id
}

output "internal_security_group_id" {
  description = "The ID of the internal jump host security group"
  value       = module.jump_host.internal_security_group_id
}

# CloudWatch Logs
output "cloudwatch_log_groups" {
  description = "Map of CloudWatch log group names"
  value       = module.jump_host.cloudwatch_log_groups
}

# Connection Guide
output "connection_guide" {
  description = "Guide for connecting to jump hosts"
  value       = module.jump_host.connection_guide
}
