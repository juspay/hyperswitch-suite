# ============================================================================
# Broker Instance Information
# ============================================================================
output "broker_instance_ids" {
  description = "List of IDs of the Kafka broker instances"
  value       = aws_instance.broker[*].id
}

output "broker_instance_private_ips" {
  description = "List of private IP addresses of the Kafka broker instances"
  value       = aws_instance.broker[*].private_ip
}

# ============================================================================
# Controller Instance Information
# ============================================================================
output "controller_instance_ids" {
  description = "List of IDs of the Kafka controller instances"
  value       = aws_instance.controller[*].id
}

output "controller_instance_private_ips" {
  description = "List of private IP addresses of the Kafka controller instances"
  value       = aws_instance.controller[*].private_ip
}

# ============================================================================
# Network Interface Information (Brokers)
# ============================================================================
output "broker_eni_ids" {
  description = "List of ENI IDs attached to Kafka broker instances"
  value       = aws_network_interface.broker[*].id
}

output "broker_eni_private_ips" {
  description = "List of private IPs of the broker ENIs"
  value       = aws_network_interface.broker[*].private_ip
}

output "broker_ips_string_list" {
  description = "Comma-separated list of private IPs of the broker ENIs"
  value       = join(":9092,", aws_network_interface.broker[*].private_ip)
}

# ============================================================================
# Network Interface Information (Controllers)
# ============================================================================
output "controller_eni_ids" {
  description = "List of ENI IDs attached to Kafka controller instances"
  value       = aws_network_interface.controller[*].id
}

output "controller_eni_private_ips" {
  description = "List of private IPs of the controller ENIs"
  value       = aws_network_interface.controller[*].private_ip
}

# ============================================================================
# Security Configuration
# ============================================================================
output "broker_security_group_id" {
  description = "Security group ID of the Kafka broker nodes"
  value       = aws_security_group.broker.id
}

output "controller_security_group_id" {
  description = "Security group ID of the Kafka controller nodes"
  value       = aws_security_group.controller.id
}

# ============================================================================
# SSH Key Information
# ============================================================================
output "key_name" {
  description = "SSH key pair name used for Kafka instances"
  value       = local.key_name
}

output "ssh_private_key_ssm_parameter" {
  description = "SSM Parameter Store path for the auto-generated SSH private key (null if not auto-generated)"
  value       = var.create_key_pair && var.public_key == null ? aws_ssm_parameter.kafka_private_key[0].name : null
}

# ============================================================================
# IAM Information
# ============================================================================
output "iam_role_arn" {
  description = "ARN of the IAM role attached to Kafka instances"
  value       = aws_iam_role.kafka.arn
}

output "iam_role_name" {
  description = "Name of the IAM role attached to Kafka instances"
  value       = aws_iam_role.kafka.name
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile for Kafka instances"
  value       = aws_iam_instance_profile.kafka.name
}
