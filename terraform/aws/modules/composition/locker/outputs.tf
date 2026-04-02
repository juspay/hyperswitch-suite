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

output "alb_security_group_id" {
  description = "Security group ID of the locker ALB"
  value       = aws_security_group.alb.id
}

output "subnet_ids" {
  description = "Subnet IDs where the locker instances are deployed"
  value       = local.locker_subnet_ids
}

output "key_name" {
  description = "SSH key pair name used for the locker instance"
  value       = local.key_name
}

output "ssh_private_key_ssm_parameter" {
  description = "SSM Parameter Store path where the auto-generated SSH private key is stored (only populated if key pair was auto-generated)"
  value       = var.create_key_pair && var.public_key == null ? aws_ssm_parameter.locker_private_key[0].name : null
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.locker_alb.dns_name
}

output "alb_listener_arns" {
  description = "ARNs of the ALB listeners"
  value       = { for key, listener in aws_lb_listener.locker : key => listener.arn }
}

output "alb_listener_details" {
  description = "Details of the ALB listeners (port and protocol)"
  value = { for key, listener in var.alb_listeners : key => {
    port     = listener.port
    protocol = listener.protocol
  } }
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
  value       = var.create_locker_database && var.database_config != null ? module.database[0].endpoint : null
}

output "db_cluster_reader_endpoint" {
  description = "The reader endpoint of the RDS Aurora database"
  value       = var.create_locker_database && var.database_config != null ? module.database[0].reader_endpoint : null
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
