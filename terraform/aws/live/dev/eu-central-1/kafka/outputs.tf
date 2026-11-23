# ============================================================================
# Kafka Outputs
# ============================================================================

# Broker Instance Information
output "kafka_broker_instance_ids" {
  description = "List of IDs of the Kafka broker instances"
  value       = module.kafka.broker_instance_ids
}

output "kafka_broker_private_ips" {
  description = "List of private IP addresses of the Kafka broker instances"
  value       = module.kafka.broker_instance_private_ips
}

# Controller Instance Information
output "kafka_controller_instance_ids" {
  description = "List of IDs of the Kafka controller instances"
  value       = module.kafka.controller_instance_ids
}

output "kafka_controller_private_ips" {
  description = "List of private IP addresses of the Kafka controller instances"
  value       = module.kafka.controller_instance_private_ips
}

# ENI Information (Brokers)
output "kafka_broker_eni_ids" {
  description = "List of ENI IDs attached to Kafka broker instances"
  value       = module.kafka.broker_eni_ids
}

output "kafka_broker_eni_private_ips" {
  description = "List of private IPs of the broker ENIs"
  value       = module.kafka.broker_eni_private_ips
}

# ENI Information (Controllers)
output "kafka_controller_eni_ids" {
  description = "List of ENI IDs attached to Kafka controller instances"
  value       = module.kafka.controller_eni_ids
}

output "kafka_controller_eni_private_ips" {
  description = "List of private IPs of the controller ENIs"
  value       = module.kafka.controller_eni_private_ips
}

# Security Configuration
output "kafka_broker_security_group_id" {
  description = "Security group ID of the Kafka broker nodes"
  value       = module.kafka.broker_security_group_id
}

output "kafka_controller_security_group_id" {
  description = "Security group ID of the Kafka controller nodes"
  value       = module.kafka.controller_security_group_id
}

# SSH Key Information
output "kafka_key_name" {
  description = "SSH key pair name used for Kafka instances"
  value       = module.kafka.key_name
}

output "kafka_ssh_private_key_ssm_parameter" {
  description = "SSM Parameter Store path for the auto-generated SSH private key (null if not auto-generated)"
  value       = module.kafka.ssh_private_key_ssm_parameter
}

# IAM Information
output "kafka_iam_role_arn" {
  description = "ARN of the IAM role attached to Kafka instances"
  value       = module.kafka.iam_role_arn
}

output "kafka_iam_role_name" {
  description = "Name of the IAM role attached to Kafka instances"
  value       = module.kafka.iam_role_name
}

output "kafka_instance_profile_name" {
  description = "Name of the IAM instance profile for Kafka instances"
  value       = module.kafka.instance_profile_name
}
