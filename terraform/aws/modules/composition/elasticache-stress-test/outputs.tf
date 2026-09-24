output "lambda_function_arns" {
  description = "Map of stress type to Lambda function ARN"
  value = {
    for k, v in aws_lambda_function.stress_test : k => v.arn
  }
}

output "lambda_function_names" {
  description = "Map of stress type to Lambda function name"
  value = {
    for k, v in aws_lambda_function.stress_test : k => v.function_name
  }
}

output "lambda_iam_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda.arn
}

output "lambda_layers" {
  description = "Lambda layer ARNs used by the stress test functions"
  value       = var.lambda_layers
}

output "security_group_id" {
  description = "Security group ID used by Lambda functions (created or reused)"
  value       = var.create_security_group ? aws_security_group.lambda[0].id : var.lambda_security_group_id
}

output "invoke_commands" {
  description = "AWS CLI commands to invoke each stress test Lambda function"
  value = {
    for k, v in aws_lambda_function.stress_test : k => "aws lambda invoke --function-name ${v.function_name} --region ${var.region} --payload '{}' /tmp/${k}-output.json && cat /tmp/${k}-output.json"
  }
}
