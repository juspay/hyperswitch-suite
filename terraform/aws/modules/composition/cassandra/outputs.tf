# ============================================================================
# Instance Information
# ============================================================================
output "instance_ids" {
  description = "List of IDs of the Cassandra instances"
  value       = aws_instance.cassandra[*].id
}

output "instance_private_ips" {
  description = "List of private IP addresses of the Cassandra instances"
  value       = aws_instance.cassandra[*].private_ip
}

output "instance_arns" {
  description = "List of ARNs of the Cassandra instances"
  value       = aws_instance.cassandra[*].arn
}

# ============================================================================
# Network Interface Information
# ============================================================================
output "eni_ids" {
  description = "List of ENI IDs attached to Cassandra instances (stable IPs)"
  value       = aws_network_interface.cassandra[*].id
}

output "eni_private_ips" {
  description = "List of private IPs of the ENIs (stable across instance replacements)"
  value       = aws_network_interface.cassandra[*].private_ip
}

# ============================================================================
# Cluster Configuration
# ============================================================================
output "cluster_name" {
  description = "Cassandra cluster name"
  value       = var.cluster_name
}

output "seeds_url" {
  description = "URL of the seed discovery API used by this cluster"
  value       = local.create_seed_discovery ? "${module.seed_discovery_api[0].invoke_url}/CassandraSeedNode" : var.seeds_url
}

output "native_port" {
  description = "Cassandra CQL native transport port"
  value       = var.cassandra_ports.native
}

# ============================================================================
# Security Configuration
# ============================================================================
output "cassandra_security_group_id" {
  description = "Security group ID of the Cassandra cluster"
  value       = module.cassandra_sg.sg_id
}

output "cassandra_security_group_arn" {
  description = "Security group ARN of the Cassandra cluster"
  value       = module.cassandra_sg.sg_arn
}

output "subnet_id" {
  description = "Subnet ID where the Cassandra instances are deployed"
  value       = local.cassandra_subnet_id
}

# ============================================================================
# SSH Key Information
# ============================================================================
output "key_name" {
  description = "SSH key pair name used for Cassandra instances"
  value       = local.key_name
}

output "ssh_private_key_ssm_parameter" {
  description = "SSM Parameter Store path for the auto-generated SSH private key (null if not auto-generated)"
  value       = var.create_key_pair && var.public_key == null ? aws_ssm_parameter.cassandra_private_key[0].name : null
}

# ============================================================================
# IAM Information
# ============================================================================
output "iam_role_arn" {
  description = "ARN of the IAM role attached to Cassandra instances"
  value       = module.cassandra_iam_role.role_arn
}

output "iam_role_name" {
  description = "Name of the IAM role attached to Cassandra instances"
  value       = module.cassandra_iam_role.role_name
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile for Cassandra instances"
  value       = module.cassandra_iam_role.instance_profile_name
}

output "instance_profile_arn" {
  description = "ARN of the IAM instance profile for Cassandra instances"
  value       = module.cassandra_iam_role.instance_profile_arn
}

# ============================================================================
# Seed Discovery Lambda Information
# ============================================================================
output "seed_discovery_lambda_function_name" {
  description = "Name of the seed discovery Lambda function"
  value       = local.create_seed_discovery ? module.seed_discovery_lambda[0].function_name : null
}

output "seed_discovery_lambda_function_arn" {
  description = "ARN of the seed discovery Lambda function"
  value       = local.create_seed_discovery ? module.seed_discovery_lambda[0].function_arn : null
}

# ============================================================================
# Seed Discovery API Gateway Information
# ============================================================================
output "seed_discovery_api_id" {
  description = "ID of the seed discovery API Gateway"
  value       = local.create_seed_discovery ? module.seed_discovery_api[0].rest_api_id : null
}

output "seed_discovery_api_invoke_url" {
  description = "Invoke URL of the seed discovery API Gateway"
  value       = local.create_seed_discovery ? module.seed_discovery_api[0].invoke_url : null
}