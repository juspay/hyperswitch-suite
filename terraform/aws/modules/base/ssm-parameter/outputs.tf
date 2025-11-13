output "parameter_name" {
  description = "The name of the parameter"
  value       = aws_ssm_parameter.this.name
}

output "parameter_arn" {
  description = "The ARN of the parameter"
  value       = aws_ssm_parameter.this.arn
}

output "parameter_type" {
  description = "The type of the parameter"
  value       = aws_ssm_parameter.this.type
}

output "parameter_version" {
  description = "The version of the parameter"
  value       = aws_ssm_parameter.this.version
}
