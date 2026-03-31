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
  description = "ARN of the IAM role for OpenTelemetry Collector application"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role for OpenTelemetry Collector application"
  value       = aws_iam_role.this.name
}

output "role_id" {
  description = "ID of the IAM role for OpenTelemetry Collector application"
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

output "otel_collector_policy_enabled" {
  description = "Whether OpenTelemetry Collector inline policy is created"
  value       = var.create_otel_collector_policy
}

output "cloudwatch_logs_enabled" {
  description = "Whether CloudWatch Logs permissions are enabled"
  value       = var.enable_cloudwatch_logs
}

output "cloudwatch_metrics_enabled" {
  description = "Whether CloudWatch Metrics permissions are enabled"
  value       = var.enable_cloudwatch_metrics
}

output "xray_tracing_enabled" {
  description = "Whether X-Ray tracing permissions are enabled"
  value       = var.enable_xray_tracing
}

output "s3_export_enabled" {
  description = "Whether S3 export permissions are enabled"
  value       = var.enable_s3_export
}

output "kinesis_firehose_enabled" {
  description = "Whether Kinesis Data Firehose permissions are enabled"
  value       = var.enable_kinesis_firehose
}
