output "jump_instance_id" {
  description = "The ID of the jump host instance"
  value       = module.jump_instance.id
}

output "jump_private_ip" {
  description = "The private IP address of the jump host"
  value       = module.jump_instance.private_ip
}

output "jump_ssm_command" {
  description = "AWS CLI command to connect to jump host via Session Manager"
  value       = "aws ssm start-session --target ${module.jump_instance.id}"
}

output "jump_iam_role_arn" {
  description = "The ARN of the IAM role for the jump host"
  value       = module.jump_iam_role.arn
}

output "jump_iam_role_name" {
  description = "The name of the IAM role for the jump host"
  value       = module.jump_iam_role.name
}

output "jump_security_group_id" {
  description = "The ID of the jump host security group"
  value       = module.jump_sg.security_group_id
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for jump host logs"
  value       = aws_cloudwatch_log_group.jump_host.name
}

output "migration_mode_status" {
  description = "Current migration mode status for SSM SendCommand permissions"
  value       = var.enable_migration_mode ? "ENABLED" : "DISABLED"
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
  description = "Guide for connecting to the jump host"
  value = templatefile("${path.module}/templates/connection_guide.tftpl", {
    instance_id     = module.jump_instance.id
    log_group       = aws_cloudwatch_log_group.jump_host.name
    ssm_run_as_user = var.ssm_run_as_user
  })
}
