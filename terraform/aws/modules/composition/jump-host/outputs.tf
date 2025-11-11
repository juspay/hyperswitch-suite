output "external_jump_instance_id" {
  description = "The ID of the external jump host instance"
  value       = module.external_jump_instance.instance_id
}

output "external_jump_private_ip" {
  description = "The private IP address of the external jump host"
  value       = module.external_jump_instance.private_ip
}

output "external_jump_public_ip" {
  description = "The public IP address of the external jump host"
  value       = module.external_jump_instance.public_ip
}

output "external_jump_ssm_command" {
  description = "AWS CLI command to connect to external jump host via Session Manager"
  value       = module.external_jump_instance.ssm_session_command
}

output "internal_jump_instance_id" {
  description = "The ID of the internal jump host instance"
  value       = module.internal_jump_instance.instance_id
}

output "internal_jump_private_ip" {
  description = "The private IP address of the internal jump host"
  value       = module.internal_jump_instance.private_ip
}

output "internal_jump_ssm_command" {
  description = "AWS CLI command to connect to internal jump host via Session Manager"
  value       = module.internal_jump_instance.ssm_session_command
}

output "iam_role_arn" {
  description = "The ARN of the IAM role for jump hosts"
  value       = module.jump_host_iam_role.role_arn
}

output "iam_instance_profile_name" {
  description = "The name of the IAM instance profile for jump hosts"
  value       = module.jump_host_iam_role.instance_profile_name
}

output "external_security_group_id" {
  description = "The ID of the external jump host security group"
  value       = module.external_jump_sg.sg_id
}

output "internal_security_group_id" {
  description = "The ID of the internal jump host security group"
  value       = module.internal_jump_sg.sg_id
}

output "cloudwatch_log_groups" {
  description = "Map of CloudWatch log group names"
  value = {
    external = aws_cloudwatch_log_group.jump_host["external"].name
    internal = aws_cloudwatch_log_group.jump_host["internal"].name
  }
}

output "connection_guide" {
  description = "Guide for connecting to jump hosts"
  value = <<-EOT
    Connect to External Jump Host:
      ${module.external_jump_instance.ssm_session_command}

    Connect to Internal Jump Host:
      ${module.internal_jump_instance.ssm_session_command}

    View Logs:
      External: aws logs tail ${aws_cloudwatch_log_group.jump_host["external"].name} --follow
      Internal: aws logs tail ${aws_cloudwatch_log_group.jump_host["internal"].name} --follow

    Note: Ensure you have AWS Session Manager plugin installed:
      https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
  EOT
}
