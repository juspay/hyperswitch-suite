output "region" {
  description = "AWS region where resources are managed"
  value       = local.region
}

output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "database_enabled" {
  description = "Whether the database is created"
  value       = var.create_database
}

output "database_cluster_id" {
  description = "Aurora cluster ID"
  value       = var.create_database ? module.database[0].cluster_id : null
}

output "database_cluster_arn" {
  description = "Aurora cluster ARN"
  value       = var.create_database ? module.database[0].cluster_arn : null
}

output "database_endpoint" {
  description = "Aurora writer endpoint"
  value       = var.create_database ? module.database[0].endpoint : null
}

output "database_reader_endpoint" {
  description = "Aurora reader endpoint"
  value       = var.create_database ? module.database[0].reader_endpoint : null
}

output "database_security_group_id" {
  description = "ID of the dedicated database security group. Use this output for ingress-rule dependencies"
  value       = var.create_database ? module.database[0].security_group_id : null
}

output "database_port" {
  description = "Database port"
  value       = var.create_database ? module.database[0].port : null
}

output "database_name" {
  description = "Database name"
  value       = var.create_database ? module.database[0].database_name : null
}

output "database_master_user_secret_arn" {
  description = "ARN of the RDS-managed master-user secret"
  value       = var.create_database ? try(module.database[0].master_user_secret[0].secret_arn, null) : null
  sensitive   = true
}

output "database_custom_parameter_group_name" {
  description = "Name of the custom Aurora cluster parameter group"
  value       = var.create_database ? module.database[0].custom_parameter_group_name : null
}

output "db_global_cluster_id" {
  description = "Aurora global cluster ID"
  value       = var.create_database ? module.database[0].global_cluster_id : null
}

output "db_global_cluster_arn" {
  description = "Aurora global cluster ARN"
  value       = var.create_database ? module.database[0].global_cluster_arn : null
}

output "application_secret_arn" {
  description = "ARN of the created or existing application secret"
  value = var.create_application_secret ? aws_secretsmanager_secret.application[0].arn : (
    var.existing_application_secret_arn != null ? data.aws_secretsmanager_secret.existing_application[0].arn : null
  )
}

output "application_secret_name" {
  description = "Name of the created or existing application secret"
  value = var.create_application_secret ? aws_secretsmanager_secret.application[0].name : (
    var.existing_application_secret_arn != null ? data.aws_secretsmanager_secret.existing_application[0].name : null
  )
}

output "kms_key_enabled" {
  description = "Whether a created or existing KMS key is configured"
  value       = local.kms_enabled
}

output "kms_key_arn" {
  description = "ARN of the created or existing KMS key"
  value       = local.kms_key_arn
}

output "kms_key_id" {
  description = "ID of the created or existing KMS key"
  value       = local.kms_key_id
}

output "kms_aliases" {
  description = "Aliases created by this module; empty for an existing key"
  value       = local.kms_enabled ? (var.kms.create ? module.kms[0].aliases : {}) : null
}

output "role_arn" {
  description = "ARN of the Invokr IAM/IRSA role"
  value       = var.create_iam_role ? aws_iam_role.this[0].arn : null
}

output "iam_role_name" {
  description = "Name of the Invokr IAM/IRSA role"
  value       = var.create_iam_role ? aws_iam_role.this[0].name : null
}

output "iam_role_id" {
  description = "ID of the Invokr IAM/IRSA role"
  value       = var.create_iam_role ? aws_iam_role.this[0].id : null
}
