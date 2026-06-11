# ============================================================================
# Clickhouse Outputs
# ============================================================================

# SSH Key Information
output "clickhouse_key_pair_name" {
  description = "Name of the SSH key pair used for Clickhouse instances"
  value       = module.clickhouse.key_pair_name
}

output "clickhouse_private_key_ssm_parameter" {
  description = "SSM parameter name where private key is stored (if auto-generated)"
  value       = module.clickhouse.private_key_ssm_parameter
}

# Security Configuration
output "clickhouse_keeper_security_group_id" {
  description = "ID of the security group for Clickhouse keeper nodes"
  value       = module.clickhouse.keeper_security_group_id
}

output "clickhouse_server_security_group_id" {
  description = "ID of the security group for Clickhouse server nodes"
  value       = module.clickhouse.server_security_group_id
}

# IAM Information
output "clickhouse_iam_role_name" {
  description = "Name of the IAM role for Clickhouse instances"
  value       = module.clickhouse.iam_role_name
}

output "clickhouse_iam_role_arn" {
  description = "ARN of the IAM role for Clickhouse instances"
  value       = module.clickhouse.iam_role_arn
}

output "clickhouse_instance_profile_name" {
  description = "Name of the IAM instance profile for Clickhouse instances"
  value       = module.clickhouse.instance_profile_name
}

# Keeper Instance Information
output "clickhouse_keeper_instance_ids" {
  description = "IDs of the Clickhouse keeper EC2 instances"
  value       = module.clickhouse.keeper_instance_ids
}

output "clickhouse_keeper_private_ips" {
  description = "Private IP addresses of the Clickhouse keeper instances"
  value       = module.clickhouse.keeper_private_ips
}

output "clickhouse_keeper_eni_ids" {
  description = "IDs of the Clickhouse keeper network interfaces"
  value       = module.clickhouse.keeper_eni_ids
}

output "clickhouse_keeper_eni_private_ips" {
  description = "Private IP addresses of the Clickhouse keeper network interfaces"
  value       = module.clickhouse.keeper_eni_private_ips
}

# Server Instance Information
output "clickhouse_server_instance_ids" {
  description = "IDs of the Clickhouse server EC2 instances"
  value       = module.clickhouse.server_instance_ids
}

output "clickhouse_server_private_ips" {
  description = "Private IP addresses of the Clickhouse server instances"
  value       = module.clickhouse.server_private_ips
}

output "clickhouse_server_eni_ids" {
  description = "IDs of the Clickhouse server network interfaces"
  value       = module.clickhouse.server_eni_ids
}

output "clickhouse_server_eni_private_ips" {
  description = "Private IP addresses of the Clickhouse server network interfaces"
  value       = module.clickhouse.server_eni_private_ips
}

# Cluster Info
output "clickhouse_cluster_info" {
  description = "Summary information about the Clickhouse cluster"
  value       = module.clickhouse.cluster_info
}
