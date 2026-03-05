output "instance_ids" {
  description = "List of IDs of the locker instances"
  value       = module.locker_instance[*].id
}

output "instance_private_ips" {
  description = "List of private IP addresses of the locker instances"
  value       = module.locker_instance[*].private_ip
}

output "instance_arns" {
  description = "List of ARNs of the locker instances"
  value       = module.locker_instance[*].arn
}

output "locker_port" {
  description = "Port number used for the locker service"
  value       = var.locker_port
}

output "security_group_id" {
  description = "Security group ID of the locker instance"
  value       = local.locker_security_group_id
}

output "nlb_security_group_id" {
  description = "Security group ID of the locker NLB"
  value       = aws_security_group.nlb.id
}

output "subnet_id" {
  description = "Subnet ID where the locker instance is deployed"
  value       = local.locker_subnet_id
}

output "key_name" {
  description = "SSH key pair name used for the locker instance"
  value       = local.key_name
}

output "ssh_private_key_ssm_parameter" {
  description = "SSM Parameter Store path where the auto-generated SSH private key is stored (only populated if key pair was auto-generated)"
  value       = var.create_key_pair && var.public_key == null ? aws_ssm_parameter.locker_private_key[0].name : null
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.locker_nlb.dns_name
}

output "nlb_listener_arns" {
  description = "ARNs of the NLB listeners"
  value       = { for key, listener in aws_lb_listener.locker : key => listener.arn }
}

output "nlb_listener_details" {
  description = "Details of the NLB listeners (port and protocol)"
  value       = { for key, listener in var.nlb_listeners : key => {
    port     = listener.port
    protocol = listener.protocol
  }}
}

# =========================================================================
# KMS Outputs
# =========================================================================
output "kms_key_arn" {
  description = "The ARN of the created KMS key"
  value       = local.kms_create ? module.kms[0].key_arn : null
}

output "kms_key_id" {
  description = "The ID of the created KMS key"
  value       = local.kms_create ? module.kms[0].key_id : null
}

output "kms_key_aliases" {
  description = "The aliases of the created KMS key"
  value       = local.kms_create ? module.kms[0].aliases : null
}

output "kms_key_arns" {
  description = "List of all KMS key ARNs (created + additional)"
  value       = local.kms_key_arns
}

# =========================================================================
# Database Outputs
# =========================================================================
output "db_cluster_endpoint" {
  description = "The cluster endpoint of the RDS Aurora database"
  value       = var.create_locker_database && var.database_config != null ? module.database[0].cluster_endpoint : null
}

output "db_cluster_reader_endpoint" {
  description = "The reader endpoint of the RDS Aurora database"
  value       = var.create_locker_database && var.database_config != null ? module.database[0].cluster_reader_endpoint : null
}

output "db_cluster_arn" {
  description = "The ARN of the RDS Aurora database cluster"
  value       = var.create_locker_database && var.database_config != null ? module.database[0].cluster_arn : null
}

output "db_security_group_id" {
  description = "The security group ID of the RDS database"
  value       = var.create_locker_database && var.database_config != null ? module.database[0].security_group_id : null
}

output "db_subnet_group_id" {
  description = "The subnet group ID of the RDS database"
  value       = var.create_locker_database && var.database_config != null ? module.database[0].db_subnet_group_id : null
}

output "db_instance_endpoints" {
  description = "Map of instance endpoints for the RDS cluster"
  value       = var.create_locker_database && var.database_config != null ? module.database[0].cluster_instance_endpoints : null
}
