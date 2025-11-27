# Aurora Cluster Information
output "cluster_id" {
  description = "Aurora cluster identifier"
  value       = module.aurora_postgresql.cluster_id
}

output "cluster_arn" {
  description = "Aurora cluster ARN"
  value       = module.aurora_postgresql.cluster_arn
}

output "cluster_endpoint" {
  description = "Aurora cluster write endpoint"
  value       = module.aurora_postgresql.cluster_endpoint
}

output "cluster_reader_endpoint" {
  description = "Aurora cluster read endpoint"
  value       = module.aurora_postgresql.cluster_reader_endpoint
}

output "cluster_port" {
  description = "Aurora cluster port"
  value       = module.aurora_postgresql.cluster_port
}

output "cluster_database_name" {
  description = "Aurora cluster database name"
  value       = module.aurora_postgresql.cluster_database_name
}

# Instance Information
output "cluster_instances" {
  description = "Aurora cluster instance information"
  value       = module.aurora_postgresql.cluster_instances
}

output "primary_instance_endpoint" {
  description = "Primary Aurora instance endpoint"
  value       = try(module.aurora_postgresql.cluster_instances.primary.endpoint, null)
}

output "replica_instance_endpoint" {
  description = "Replica Aurora instance endpoint"
  value       = try(module.aurora_postgresql.cluster_instances.replica.endpoint, null)
}

# Security and Access
output "security_group_id" {
  description = "Aurora database security group ID"
  value       = aws_security_group.aurora_db.id
}

output "security_group_arn" {
  description = "Aurora database security group ARN"
  value       = aws_security_group.aurora_db.arn
}

output "db_subnet_group_name" {
  description = "Database subnet group name"
  value       = aws_db_subnet_group.aurora.name
}

output "db_subnet_group_arn" {
  description = "Database subnet group ARN"
  value       = aws_db_subnet_group.aurora.arn
}

# Credentials and Secrets
output "master_user_secret" {
  description = "Aurora master user secret information"
  value       = module.aurora_postgresql.cluster_master_user_secret
  sensitive   = true
}

output "master_user_secret_arn" {
  description = "Aurora master user secret ARN"
  value       = try(module.aurora_postgresql.cluster_master_user_secret[0].secret_arn, null)
}

# Monitoring and Performance
output "enhanced_monitoring_iam_role_arn" {
  description = "Enhanced monitoring IAM role ARN"
  value       = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
}

output "performance_insights_enabled" {
  description = "Whether Performance Insights is enabled"
  value       = var.performance_insights_enabled
}

# Parameter Groups
output "cluster_parameter_group_name" {
  description = "Aurora cluster parameter group name"
  value       = aws_rds_cluster_parameter_group.postgresql.name
}

output "db_parameter_group_name" {
  description = "Aurora DB parameter group name"
  value       = aws_db_parameter_group.postgresql.name
}

# Connection Information
output "connection_info" {
  description = "Aurora cluster connection information and usage examples"
  value = <<-EOF
# Aurora PostgreSQL Cluster Connection Information

## Cluster Details
- **Cluster Name**: ${module.aurora_postgresql.cluster_id}
- **Engine**: Aurora PostgreSQL ${var.engine_version}
- **Write Endpoint**: ${module.aurora_postgresql.cluster_endpoint}:${module.aurora_postgresql.cluster_port}
- **Read Endpoint**: ${module.aurora_postgresql.cluster_reader_endpoint}:${module.aurora_postgresql.cluster_port}
- **Database Name**: ${module.aurora_postgresql.cluster_database_name}
${var.enable_rds_proxy ? "- **RDS Proxy Endpoint**: ${aws_db_proxy.aurora_proxy[0].endpoint}:${module.aurora_postgresql.cluster_port}" : ""}

## Security Configuration
- **Database Security Group**: ${aws_security_group.aurora_db.id}
${var.enable_rds_proxy ? "- **RDS Proxy Security Group**: ${aws_security_group.rds_proxy[0].id}" : ""}
- **Allowed Inbound**: Application SG (${var.application_security_group_id}) on port 5432${var.enable_rds_proxy ? " via RDS Proxy" : " direct to Aurora"}
- **Outbound Rules**: ${var.enable_rds_proxy ? "RDS Proxy → Aurora cluster only" : "None (as specified)"}

## Credentials Access
The master user credentials are stored in AWS Secrets Manager:
```bash
# Get credentials from Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id ${try(module.aurora_postgresql.cluster_master_user_secret[0].secret_arn, "NOT_AVAILABLE")} \
  --query SecretString --output text | jq .
```

## Connection Examples

### Using psql from Jump Host
${var.enable_rds_proxy ? "#### Via RDS Proxy (Recommended - with connection pooling)" : ""}
${var.enable_rds_proxy ? "```bash" : ""}
${var.enable_rds_proxy ? "# Connect via RDS Proxy (handles connection pooling and failover)" : ""}
${var.enable_rds_proxy ? "psql -h ${aws_db_proxy.aurora_proxy[0].endpoint} \\" : ""}
${var.enable_rds_proxy ? "     -p ${module.aurora_postgresql.cluster_port} \\" : ""}
${var.enable_rds_proxy ? "     -U ${var.master_username} \\" : ""}
${var.enable_rds_proxy ? "     -d ${module.aurora_postgresql.cluster_database_name}" : ""}
${var.enable_rds_proxy ? "```" : ""}

${var.enable_rds_proxy ? "#### Direct to Aurora (Alternative)" : ""}
```bash
# Connect to write endpoint (primary)
psql -h ${module.aurora_postgresql.cluster_endpoint} \
     -p ${module.aurora_postgresql.cluster_port} \
     -U ${var.master_username} \
     -d ${module.aurora_postgresql.cluster_database_name}

# Connect to read endpoint (replica)
psql -h ${module.aurora_postgresql.cluster_reader_endpoint} \
     -p ${module.aurora_postgresql.cluster_port} \
     -U ${var.master_username} \
     -d ${module.aurora_postgresql.cluster_database_name}
```

### Application Configuration
${var.enable_rds_proxy ? "#### Using RDS Proxy (Recommended)" : ""}
${var.enable_rds_proxy ? "```yaml" : ""}
${var.enable_rds_proxy ? "database:" : ""}
${var.enable_rds_proxy ? "  host: ${aws_db_proxy.aurora_proxy[0].endpoint}" : ""}
${var.enable_rds_proxy ? "  port: ${module.aurora_postgresql.cluster_port}" : ""}
${var.enable_rds_proxy ? "  database: ${module.aurora_postgresql.cluster_database_name}" : ""}
${var.enable_rds_proxy ? "  username: ${var.master_username}" : ""}
${var.enable_rds_proxy ? "  # Get password from AWS Secrets Manager" : ""}
${var.enable_rds_proxy ? "  # RDS Proxy handles connection pooling and failover automatically" : ""}
${var.enable_rds_proxy ? "```" : ""}

${var.enable_rds_proxy ? "#### Direct Aurora Connection (Alternative)" : ""}
```yaml
database:
  host: ${module.aurora_postgresql.cluster_endpoint}
  port: ${module.aurora_postgresql.cluster_port}
  database: ${module.aurora_postgresql.cluster_database_name}
  username: ${var.master_username}
  # Get password from AWS Secrets Manager

# For read-only operations, use:
read_replica:
  host: ${module.aurora_postgresql.cluster_reader_endpoint}
  port: ${module.aurora_postgresql.cluster_port}
```

## Instance Information
- **Primary Instance**: ${try(module.aurora_postgresql.cluster_instances.primary.identifier, "primary")}
- **Replica Instance**: ${try(module.aurora_postgresql.cluster_instances.replica.identifier, "replica")}
- **Instance Class**: ${local.instance_class}

## Backup Configuration
- **Backup Retention**: ${var.backup_retention_period} days
- **Backup Window**: ${var.backup_window} UTC
- **Maintenance Window**: ${var.maintenance_window} UTC

## Monitoring
- **Enhanced Monitoring**: ${var.monitoring_interval > 0 ? "Enabled (${var.monitoring_interval}s interval)" : "Disabled"}
- **Performance Insights**: ${var.performance_insights_enabled ? "Enabled" : "Disabled"}
- **CloudWatch Logs**: PostgreSQL logs exported

## Security Features
- **Encryption at Rest**: Enabled
- **Encryption in Transit**: Enabled (SSL/TLS)
- **Deletion Protection**: ${var.deletion_protection ? "Enabled" : "Disabled"}
EOF
}

# =============================================================================
# RDS PROXY OUTPUTS (CONDITIONAL)
# =============================================================================

output "rds_proxy_enabled" {
  description = "Whether RDS Proxy is enabled"
  value       = var.enable_rds_proxy
}

output "rds_proxy_endpoint" {
  description = "RDS Proxy endpoint (when enabled)"
  value       = var.enable_rds_proxy ? aws_db_proxy.aurora_proxy[0].endpoint : null
}

output "rds_proxy_arn" {
  description = "RDS Proxy ARN (when enabled)"
  value       = var.enable_rds_proxy ? aws_db_proxy.aurora_proxy[0].arn : null
}

output "rds_proxy_security_group_id" {
  description = "RDS Proxy security group ID (when enabled)"
  value       = var.enable_rds_proxy ? aws_security_group.rds_proxy[0].id : null
}

output "rds_proxy_iam_role_arn" {
  description = "RDS Proxy IAM role ARN (when enabled)"
  value       = var.enable_rds_proxy ? aws_iam_role.rds_proxy[0].arn : null
}

# Environment Information
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "cluster_tags" {
  description = "Tags applied to the Aurora cluster"
  value       = local.common_tags
}