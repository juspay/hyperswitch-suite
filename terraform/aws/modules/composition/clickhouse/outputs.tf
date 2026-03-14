# =========================================================================
# SSH KEY OUTPUTS
# =========================================================================

output "key_pair_name" {
  description = "Name of the SSH key pair used for Clickhouse instances"
  value       = local.key_name
}

output "key_pair_id" {
  description = "ID of the created key pair (if auto-generated)"
  value       = var.create_key_pair ? aws_key_pair.clickhouse[0].key_pair_id : null
}

output "private_key_ssm_parameter" {
  description = "SSM parameter name where private key is stored (if auto-generated)"
  value       = var.create_key_pair && var.public_key == null ? aws_ssm_parameter.clickhouse_private_key[0].name : null
}

# =========================================================================
# SECURITY GROUP OUTPUTS
# =========================================================================

output "keeper_security_group_id" {
  description = "ID of the security group for Clickhouse keeper nodes"
  value       = aws_security_group.keeper.id
}

output "server_security_group_id" {
  description = "ID of the security group for Clickhouse server nodes"
  value       = aws_security_group.server.id
}

# =========================================================================
# IAM ROLE OUTPUTS
# =========================================================================

output "iam_role_name" {
  description = "Name of the IAM role for Clickhouse instances"
  value       = aws_iam_role.clickhouse.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role for Clickhouse instances"
  value       = aws_iam_role.clickhouse.arn
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile for Clickhouse instances"
  value       = aws_iam_instance_profile.clickhouse.name
}

output "instance_profile_arn" {
  description = "ARN of the IAM instance profile for Clickhouse instances"
  value       = aws_iam_instance_profile.clickhouse.arn
}

# =========================================================================
# KEEPER OUTPUTS
# =========================================================================

output "keeper_instance_ids" {
  description = "IDs of the Clickhouse keeper EC2 instances"
  value       = aws_instance.keeper[*].id
}

output "keeper_private_ips" {
  description = "Private IP addresses of the Clickhouse keeper instances"
  value       = aws_instance.keeper[*].private_ip
}

output "keeper_eni_ids" {
  description = "IDs of the Clickhouse keeper network interfaces"
  value       = aws_network_interface.keeper[*].id
}

output "keeper_eni_private_ips" {
  description = "Private IP addresses of the Clickhouse keeper network interfaces"
  value       = aws_network_interface.keeper[*].private_ip
}

# =========================================================================
# SERVER OUTPUTS
# =========================================================================

output "server_instance_ids" {
  description = "IDs of the Clickhouse server EC2 instances"
  value       = aws_instance.server[*].id
}

output "server_private_ips" {
  description = "Private IP addresses of the Clickhouse server instances"
  value       = aws_instance.server[*].private_ip
}

output "server_eni_ids" {
  description = "IDs of the Clickhouse server network interfaces"
  value       = aws_network_interface.server[*].id
}

output "server_eni_private_ips" {
  description = "Private IP addresses of the Clickhouse server network interfaces"
  value       = aws_network_interface.server[*].private_ip
}

# =========================================================================
# CLUSTER INFO
# =========================================================================

output "cluster_info" {
  description = "Summary information about the Clickhouse cluster"
  value = {
    keeper_count = var.keeper_count
    server_count = var.server_count
    keeper_ips   = aws_instance.keeper[*].private_ip
    server_ips   = aws_instance.server[*].private_ip
  }
}