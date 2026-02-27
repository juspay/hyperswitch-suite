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

output "external_jump_ssm_command" {
  description = "AWS CLI command to connect to external jump host via Session Manager"
  value       = "aws ssm start-session --target ${module.external_jump_instance.id}"
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
  value       = var.enable_internal_jump_ssm ? "aws ssm start-session --target ${module.internal_jump_instance.id}" : "DISABLED - Internal jump has no SSM access. Connect via external jump using SSH."
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
  description = "The ARN of the IAM role for external jump host"
  value       = module.external_jump_iam_role.arn
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
  description = "The ID of the external jump host security group"
  value       = module.external_jump_sg.security_group_id
}

output "internal_security_group_id" {
  description = "The ID of the internal jump host security group"
  value       = module.internal_jump_sg.security_group_id
}

output "cloudwatch_log_groups" {
  description = "Map of CloudWatch log group names"
  value = {
    external = aws_cloudwatch_log_group.jump_host["external"].name
    internal = aws_cloudwatch_log_group.jump_host["internal"].name
  }
}

output "migration_mode_status" {
  description = "Current migration mode status for SSM SendCommand permissions"
  value = var.enable_migration_mode ? "ENABLED" : "DISABLED"
}

output "connection_guide" {
  description = "Guide for connecting to jump hosts"
  value = <<-EOT
    ================================================================================
    JUMP HOST CONNECTION GUIDE
    ================================================================================

    1. Connect to External Jump Host (via Session Manager):
       aws ssm start-session --target ${module.external_jump_instance.id}

    ${var.enable_internal_jump_ssm ? "2. Connect to Internal Jump Host (via Session Manager):\n       aws ssm start-session --target ${module.internal_jump_instance.id}\n\n    a. From External Jump, SSH to Internal Jump (alternative method):\n       ssh internal-jump\n       (SSH key is automatically configured in ${var.ssm_os_username}'s home directory)\n\n    b. Manual SSH to Internal Jump (if needed):\n       ssh -i /home/${var.ssm_os_username}/.ssh/internal_jump_key ec2-user@${module.internal_jump_instance.private_ip}" : "2. From External Jump, SSH to Internal Jump:\n       ssh internal-jump\n       (SSH key is automatically configured in ${var.ssm_os_username}'s home directory)\n\n    a. Manual SSH to Internal Jump (if needed):\n       ssh -i /home/${var.ssm_os_username}/.ssh/internal_jump_key ec2-user@${module.internal_jump_instance.private_ip}"}

    3. Retrieve Internal Jump SSH Key (from your local machine):
       ${module.internal_jump_ssh_key_parameter.ssm_parameter_name}
       aws ssm get-parameter --name ${module.internal_jump_ssh_key_parameter.ssm_parameter_name} --with-decryption --query 'Parameter.Value' --output text > internal_jump_key.pem
       chmod 400 internal_jump_key.pem

    4. View Logs:
       External: aws logs tail ${aws_cloudwatch_log_group.jump_host["external"].name} --follow
       Internal: aws logs tail ${aws_cloudwatch_log_group.jump_host["internal"].name} --follow

    IMPORTANT NOTES:
    - External Jump: Accessible via Session Manager (IAM-based auth)
    - Default user: ${var.ssm_os_username} (Amazon Linux 2023 via SSM)
    - Internal Jump: ${var.enable_internal_jump_ssm ? "Accessible via Session Manager AND SSH from external jump" : "NO Session Manager access (must SSH from external jump)"}
    - Default user: ec2-user (Amazon Linux 2023)
    - SSH key stored in SSM Parameter Store: ${module.internal_jump_ssh_key_parameter.ssm_parameter_name}

    Prerequisites:
    - AWS Session Manager plugin: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
    - IAM permissions for ssm:StartSession on${var.enable_internal_jump_ssm ? " external AND internal" : " external"} jump instance(s)
    ================================================================================
  EOT
}
