output "external_jump_instance_id" {
  description = "The ID of the external jump host instance (null when external jump is disabled)"
  value       = var.enable_external_jump ? module.external_jump_instance[0].id : null
}

output "external_jump_private_ip" {
  description = "The private IP address of the external jump host (null when external jump is disabled)"
  value       = var.enable_external_jump ? module.external_jump_instance[0].private_ip : null
}

output "external_jump_public_ip" {
  description = "The public IP address of the external jump host (null when external jump is disabled)"
  value       = var.enable_external_jump ? module.external_jump_instance[0].public_ip : null
}

output "external_jump_ssm_command" {
  description = "AWS CLI command to connect to external jump host via Session Manager (null when external jump is disabled)"
  value       = var.enable_external_jump ? "aws ssm start-session --target ${module.external_jump_instance[0].id}" : null
}

output "internal_jump_instance_id" {
  description = "The ID of the internal jump host instance"
  value       = module.internal_jump_instance.id
}

output "internal_jump_private_ip" {
  description = "The private IP address of the internal jump host"
  value       = module.internal_jump_instance.private_ip
}

output "internal_jump_ssm_command" {
  description = "AWS CLI command to connect to internal jump host via Session Manager"
  value       = local.internal_ssm_enabled ? "aws ssm start-session --target ${module.internal_jump_instance.id}" : "DISABLED - Internal jump has no SSM access. Connect via external jump using SSH."
}

output "internal_jump_ssh_key_ssm_path" {
  description = "SSM Parameter Store path for internal jump SSH private key"
  value       = module.internal_jump_ssh_key_parameter.ssm_parameter_name
}

output "internal_jump_ssh_key_retrieval_command" {
  description = "Command to retrieve internal jump SSH private key"
  value       = "aws ssm get-parameter --name ${module.internal_jump_ssh_key_parameter.ssm_parameter_name} --with-decryption --query 'Parameter.Value' --output text"
}

output "external_iam_role_arn" {
  description = "The ARN of the IAM role for external jump host (null when external jump is disabled)"
  value       = var.enable_external_jump ? module.external_jump_iam_role[0].arn : null
}

output "internal_iam_role_arn" {
  description = "The ARN of the IAM role for internal jump host"
  value       = module.internal_jump_iam_role.arn
}

output "internal_iam_role_name" {
  description = "The name of the IAM role for internal jump host"
  value       = module.internal_jump_iam_role.name
}

output "external_security_group_id" {
  description = "The ID of the external jump host security group (null when external jump is disabled)"
  value       = var.enable_external_jump ? module.external_jump_sg[0].security_group_id : null
}

output "internal_security_group_id" {
  description = "The ID of the internal jump host security group"
  value       = module.internal_jump_sg.security_group_id
}

output "cloudwatch_log_groups" {
  description = "Map of CloudWatch log group names"
  value = var.enable_external_jump ? {
    external = aws_cloudwatch_log_group.jump_host["external"].name
    internal = aws_cloudwatch_log_group.jump_host["internal"].name
    } : {
    internal = aws_cloudwatch_log_group.jump_host["internal"].name
  }
}

output "migration_mode_status" {
  description = "Current migration mode status for SSM SendCommand permissions"
  value = var.enable_migration_mode ? "ENABLED" : "DISABLED"
}

output "deployment_mode" {
  description = "Current deployment mode - 'dual' (external + internal) or 'standalone' (internal only with SSM)"
  value = var.enable_external_jump ? "dual" : "standalone"
}
output "ssm_session_preferences_document" {
  description = "Name of the SSM Session Manager preferences document (null when not created)"
  value       = var.create_ssm_session_preferences ? aws_ssm_document.session_preferences[0].name : null
}

output "ssm_cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for SSM session logs (null when not created)"
  value       = var.ssm_cloudwatch_logging_enabled ? local.ssm_cloudwatch_log_group_name : null
}

output "ssm_cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for SSM session logs (null when not created by this module)"
  value       = var.create_ssm_cloudwatch_log_group && var.ssm_cloudwatch_logging_enabled ? aws_cloudwatch_log_group.ssm_session_logs[0].arn : null
}

output "ssm_s3_bucket_name" {
  description = "Name of the S3 bucket for SSM session logs (null when not enabled)"
  value       = var.ssm_s3_logging_enabled ? local.ssm_s3_bucket_name : null
}

output "ssm_s3_bucket_arn" {
  description = "ARN of the S3 bucket for SSM session logs (null when not created by this module)"
  value       = var.create_ssm_s3_bucket && var.ssm_s3_logging_enabled ? aws_s3_bucket.ssm_session_logs[0].arn : null
}

output "connection_guide" {
  description = "Guide for connecting to jump hosts"
  value = var.enable_external_jump ? templatefile("${path.module}/templates/connection_guide_dual.tftpl", {
    external_instance_id      = module.external_jump_instance[0].id
    internal_instance_id      = module.internal_jump_instance.id
    internal_private_ip       = module.internal_jump_instance.private_ip
    ssh_key_path              = module.internal_jump_ssh_key_parameter.ssm_parameter_name
    ssm_os_username           = var.ssm_os_username
    internal_ssm_enabled      = local.internal_ssm_enabled
    external_log_group        = aws_cloudwatch_log_group.jump_host["external"].name
    internal_log_group        = aws_cloudwatch_log_group.jump_host["internal"].name
  }) : templatefile("${path.module}/templates/connection_guide_standalone.tftpl", {
    internal_instance_id      = module.internal_jump_instance.id
    ssh_key_path              = module.internal_jump_ssh_key_parameter.ssm_parameter_name
    internal_log_group        = aws_cloudwatch_log_group.jump_host["internal"].name
  })
}
