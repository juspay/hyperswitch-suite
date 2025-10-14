output "lt_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.this.id
}

output "lt_arn" {
  description = "The ARN of the launch template"
  value       = aws_launch_template.this.arn
}

output "lt_name" {
  description = "The name of the launch template"
  value       = aws_launch_template.this.name
}

output "lt_latest_version" {
  description = "The latest version of the launch template"
  value       = aws_launch_template.this.latest_version
}

output "lt_default_version" {
  description = "The default version of the launch template"
  value       = aws_launch_template.this.default_version
}
