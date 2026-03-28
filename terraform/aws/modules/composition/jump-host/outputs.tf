output "external_jump_instance_id" {
  description = "The ID of the external jump host instance"
  value       = module.external_jump_instance.id
}

output "external_jump_private_ip" {
  description = "The private IP address of the external jump host"
  value       = module.external_jump_instance.private_ip
}

output "external_jump_public_ip" {
  description = "The public IP address of the external jump host"
  value       = module.external_jump_instance.public_ip
}

output "jump_ssm_command" {
  description = "AWS CLI command to connect to jump host via Session Manager"
  value       = "aws ssm start-session --target ${module.external_jump_instance.id}"
}

output "iam_role_arn" {
  description = "The ARN of the IAM role for jump host"
  value       = module.external_jump_iam_role.arn
}

output "security_group_id" {
  description = "The ID of the jump host security group"
  value       = module.external_jump_sg.security_group_id
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.jump_host.name
}

output "migration_mode_status" {
  description = "Current migration mode status for SSM SendCommand permissions"
  value       = var.enable_migration_mode ? "ENABLED" : "DISABLED"
}

output "fleet_manager_status" {
  description = "Fleet Manager user management status and console URL"
  value       = var.enable_fleet_manager ? "ENABLED - https://console.aws.amazon.com/systems-manager/fleet-manager" : "DISABLED"
}

output "connection_guide" {
  description = "Guide for connecting to jump host"
  value       = <<-EOT
    ================================================================================
    JUMP HOST CONNECTION GUIDE
    ================================================================================

    1. Connect to Jump Host (via Session Manager):
       aws ssm start-session --target ${module.external_jump_instance.id}

    2. View Logs:
       aws logs tail ${aws_cloudwatch_log_group.jump_host.name} --follow

    IMPORTANT NOTES:
    - Jump Host: Accessible via Session Manager (IAM-based auth)
    - Default user: ${var.ssm_os_username} (Amazon Linux 2023 via SSM)
    - Fleet Manager: ${var.enable_fleet_manager ? "ENABLED" : "DISABLED"} for user management

    Prerequisites:
    - AWS Session Manager plugin: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
    - IAM permissions for ssm:StartSession on the jump instance
    ================================================================================
  EOT
}
