# ============================================================================
# Aurora Fault Injection Module - Outputs
# ============================================================================

output "lambda_function_arns" {
  description = "Map of fault type to Lambda function ARN"
  value = {
    for k, v in aws_lambda_function.fault_injection : k => v.arn
  }
}

output "lambda_function_names" {
  description = "Map of fault type to Lambda function name"
  value = {
    for k, v in aws_lambda_function.fault_injection : k => v.function_name
  }
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for Secrets Manager encryption"
  value       = aws_kms_key.this.arn
}

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.this.key_id
}

output "kms_key_alias" {
  description = "Alias of the KMS key"
  value       = aws_kms_alias.this.name
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials"
  value       = local.secret_arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = var.create_secret ? aws_secretsmanager_secret.db_credentials[0].name : data.aws_secretsmanager_secret.existing[0].name
}

output "lambda_iam_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda.arn
}

output "lambda_layers" {
  description = "Lambda layer ARNs used by the fault injection functions"
  value       = var.lambda_layers
}

output "security_group_id" {
  description = "Security group ID used by Lambda functions (created or reused)"
  value       = var.create_security_group ? aws_security_group.lambda[0].id : var.lambda_security_group_id
}

output "invoke_commands" {
  description = "AWS CLI commands to invoke each fault injection Lambda function"
  value = {
    for k, v in aws_lambda_function.fault_injection : k => "aws lambda invoke --function-name ${v.function_name} --region ${var.region} --payload '{}' /tmp/${k}-output.json && cat /tmp/${k}-output.json"
  }
}

output "stress_test_function_arns" {
  description = "Map of stress type to Lambda function ARN"
  value = {
    for k, v in aws_lambda_function.stress_test : k => v.arn
  }
}

output "stress_test_function_names" {
  description = "Map of stress type to Lambda function name"
  value = {
    for k, v in aws_lambda_function.stress_test : k => v.function_name
  }
}

output "stress_test_invoke_commands" {
  description = "AWS CLI commands to invoke each stress test Lambda function"
  value = {
    for k, v in aws_lambda_function.stress_test : k => "aws lambda invoke --function-name ${v.function_name} --region ${var.region} --payload '{}' /tmp/${k}-output.json && cat /tmp/${k}-output.json"
  }
}
