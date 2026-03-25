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
  description = "ARN of the IAM role for Grafana application"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role for Grafana application"
  value       = aws_iam_role.this.name
}

output "role_id" {
  description = "ID of the IAM role for Grafana application"
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

output "database_enabled" {
  description = "Whether database feature is enabled"
  value       = local.database_enabled
}

# =========================================================================
# DATABASE OUTPUTS
# =========================================================================
output "database_cluster_id" {
  description = "RDS Cluster Identifier (if database is created)"
  value       = var.create_database ? module.database[0].cluster_id : null
}

output "database_cluster_arn" {
  description = "ARN of the RDS cluster (if database is created)"
  value       = var.create_database ? module.database[0].cluster_arn : null
}

output "database_endpoint" {
  description = "Writer endpoint for the database (if database is created)"
  value       = var.create_database ? module.database[0].endpoint : null
}

output "database_reader_endpoint" {
  description = "Reader endpoint for the database (if database is created)"
  value       = var.create_database ? module.database[0].reader_endpoint : null
}

output "database_name" {
  description = "Name of the database (if database is created)"
  value       = var.create_database ? module.database[0].database_name : null
}

output "database_port" {
  description = "Port for the database (if database is created)"
  value       = var.create_database ? module.database[0].port : null
}

output "database_master_username" {
  description = "Master username for the database (if database is created)"
  value       = var.create_database ? module.database[0].master_username : null
  sensitive   = true
}

output "database_security_group_id" {
  description = "ID of the security group for the database (if created)"
  value       = var.create_database ? module.database[0].security_group_id : null
}

output "database_cluster_instance_ids" {
  description = "Map of cluster instance identifiers (if database is created)"
  value       = var.create_database ? module.database[0].cluster_instance_ids : null
}

output "database_cluster_instance_endpoints" {
  description = "Map of cluster instance endpoints (if database is created)"
  value       = var.create_database ? module.database[0].cluster_instance_endpoints : null
}
