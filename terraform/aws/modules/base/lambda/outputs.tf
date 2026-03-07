# ============================================================================
# Lambda Function Outputs
# ============================================================================
output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}

output "function_qualified_arn" {
  description = "Qualified ARN of the Lambda function (includes version)"
  value       = aws_lambda_function.this.qualified_arn
}

output "function_version" {
  description = "Current version of the Lambda function"
  value       = aws_lambda_function.this.version
}

output "function_source_code_hash" {
  description = "Base64-encoded SHA256 hash of the source code"
  value       = aws_lambda_function.this.source_code_hash
}

# ============================================================================
# IAM Role Outputs
# ============================================================================
output "iam_role_arn" {
  description = "ARN of the IAM role used by the Lambda function"
  value       = var.create_iam_role ? aws_iam_role.this[0].arn : var.iam_role_arn
}

output "iam_role_name" {
  description = "Name of the IAM role used by the Lambda function"
  value       = var.create_iam_role ? aws_iam_role.this[0].name : null
}

# ============================================================================
# CloudWatch Log Group Outputs
# ============================================================================
output "log_group_name" {
  description = "Name of the CloudWatch log group for the Lambda function"
  value       = var.create_log_group ? aws_cloudwatch_log_group.this[0].name : null
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group for the Lambda function"
  value       = var.create_log_group ? aws_cloudwatch_log_group.this[0].arn : null
}
