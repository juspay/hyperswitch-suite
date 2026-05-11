# =========================================================================
# GENERAL OUTPUTS
# =========================================================================
output "region" {
  description = "AWS region where resources are created"
  value       = data.aws_region.current.id
}

output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

# =========================================================================
# IAM ROLE OUTPUTS
# =========================================================================
output "role_arn" {
  description = "ARN of the IAM role for Rate Limiter application"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role for Rate Limiter application"
  value       = aws_iam_role.this.name
}

output "role_id" {
  description = "ID of the IAM role for Rate Limiter application"
  value       = aws_iam_role.this.id
}

# =========================================================================
# FEATURE ENABLEMENT OUTPUTS
# =========================================================================
output "oidc_enabled" {
  description = "Whether OIDC/IRSA feature is enabled"
  value       = local.oidc_enabled
}

output "assume_role_principals_enabled" {
  description = "Whether assume role principals feature is enabled"
  value       = local.assume_role_principals_enabled
}

output "aws_managed_policies_enabled" {
  description = "Whether AWS managed policy attachments feature is enabled"
  value       = local.aws_managed_policies_enabled
}

output "customer_managed_policies_enabled" {
  description = "Whether customer managed policy attachments feature is enabled"
  value       = local.customer_managed_policies_enabled
}

output "inline_policies_enabled" {
  description = "Whether inline policies feature is enabled"
  value       = local.inline_policies_enabled
}

output "elasticache_enabled" {
  description = "Whether ElastiCache feature is enabled"
  value       = local.elasticache_enabled
}

output "lb_security_group_enabled" {
  description = "Whether load balancer security group feature is enabled"
  value       = local.lb_security_group_enabled
}

# =========================================================================
# ELASTICACHE OUTPUTS
# =========================================================================
output "elasticache_replication_group_id" {
  description = "ID of the ElastiCache Replication Group"
  value       = var.elasticache_config.enabled ? module.elasticache[0].replication_group_id : null
}

output "elasticache_replication_group_arn" {
  description = "ARN of the ElastiCache Replication Group"
  value       = var.elasticache_config.enabled ? module.elasticache[0].replication_group_arn : null
}

output "elasticache_primary_endpoint_address" {
  description = "Address of the primary endpoint for the replication group"
  value       = var.elasticache_config.enabled ? module.elasticache[0].replication_group_primary_endpoint_address : null
}

output "elasticache_reader_endpoint_address" {
  description = "Address of the reader endpoint for the replication group"
  value       = var.elasticache_config.enabled ? module.elasticache[0].replication_group_reader_endpoint_address : null
}

output "elasticache_port" {
  description = "Port number for the replication group"
  value       = var.elasticache_config.enabled ? module.elasticache[0].replication_group_port : 6379
}

output "elasticache_connection_info" {
  description = "Connection information for the ElastiCache cluster"
  value       = var.elasticache_config.enabled ? module.elasticache[0].connection_info : null
}

output "elasticache_security_group_id" {
  description = "ID of the security group created for ElastiCache"
  value       = var.elasticache_config.enabled ? module.elasticache[0].security_group_id : null
}

output "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = var.elasticache_config.enabled ? module.elasticache[0].subnet_group_name : null
}

# =========================================================================
# LOAD BALANCER SECURITY GROUP OUTPUTS
# =========================================================================
output "lb_security_group_id" {
  description = "ID of the load balancer security group"
  value       = local.lb_security_group_enabled ? aws_security_group.lb[0].id : null
}

output "lb_security_group_arn" {
  description = "ARN of the load balancer security group"
  value       = local.lb_security_group_enabled ? aws_security_group.lb[0].arn : null
}

output "lb_security_group_name" {
  description = "Name of the load balancer security group"
  value       = local.lb_security_group_enabled ? aws_security_group.lb[0].name : null
}
