# ============================================================================
# Cassandra Outputs
# ============================================================================

# Instance Information
output "cassandra_instance_ids" {
  description = "List of IDs of the Cassandra instances"
  value       = module.cassandra.instance_ids
}

output "cassandra_private_ips" {
  description = "List of private IP addresses of the Cassandra instances"
  value       = module.cassandra.instance_private_ips
}

output "cassandra_instance_arns" {
  description = "List of ARNs of the Cassandra instances"
  value       = module.cassandra.instance_arns
}

# ENI Information
output "cassandra_eni_ids" {
  description = "List of ENI IDs attached to Cassandra instances (stable IPs)"
  value       = module.cassandra.eni_ids
}

output "cassandra_eni_private_ips" {
  description = "List of stable private IPs of the ENIs"
  value       = module.cassandra.eni_private_ips
}

# Cluster Configuration
output "cassandra_cluster_name" {
  description = "Cassandra cluster name"
  value       = module.cassandra.cluster_name
}

output "cassandra_seeds_url" {
  description = "URL of the seed discovery API"
  value       = module.cassandra.seeds_url
}

output "cassandra_native_port" {
  description = "Cassandra CQL native transport port"
  value       = module.cassandra.native_port
}

# Security Configuration
output "cassandra_security_group_id" {
  description = "Security group ID of the Cassandra cluster"
  value       = module.cassandra.security_group_id
}

output "cassandra_security_group_arn" {
  description = "Security group ARN of the Cassandra cluster"
  value       = module.cassandra.security_group_arn
}

output "cassandra_subnet_id" {
  description = "Subnet ID where the Cassandra instances are deployed"
  value       = module.cassandra.subnet_id
}

# SSH Key Information
output "cassandra_key_name" {
  description = "SSH key pair name used for Cassandra instances"
  value       = module.cassandra.key_name
}

output "cassandra_ssh_private_key_ssm_parameter" {
  description = "SSM Parameter Store path for the auto-generated SSH private key (null if not auto-generated)"
  value       = module.cassandra.ssh_private_key_ssm_parameter
}

# IAM Information
output "cassandra_iam_role_arn" {
  description = "ARN of the IAM role attached to Cassandra instances"
  value       = module.cassandra.iam_role_arn
}

output "cassandra_instance_profile_name" {
  description = "Name of the IAM instance profile for Cassandra instances"
  value       = module.cassandra.instance_profile_name
}

output "cassandra_instance_profile_arn" {
  description = "ARN of the IAM instance profile for Cassandra instances"
  value       = module.cassandra.instance_profile_arn
}
