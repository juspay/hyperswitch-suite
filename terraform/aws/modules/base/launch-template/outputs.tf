output "lt_id" {
  description = "The ID of the launch template"
  value       = try(aws_launch_template.this[0].id, "")
}

output "lt_arn" {
  description = "The ARN of the launch template"
  value       = try(aws_launch_template.this[0].arn, "")
}

output "lt_name" {
  description = "The name of the launch template"
  value       = try(aws_launch_template.this[0].name, "")
}

output "lt_latest_version" {
  description = "The latest version of the launch template"
  value       = try(aws_launch_template.this[0].latest_version, "")
}

output "lt_default_version" {
  description = "The default version of the launch template"
  value       = try(aws_launch_template.this[0].default_version, "")
}
