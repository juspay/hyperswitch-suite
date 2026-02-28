output "table_id" {
  description = "The ID (name) of the table"
  value       = try(aws_dynamodb_table.this[0].id, "")
}

output "table_name" {
  description = "The name of the table"
  value       = try(aws_dynamodb_table.this[0].name, "")
}

output "table_arn" {
  description = "The ARN of the table"
  value       = try(aws_dynamodb_table.this[0].arn, "")
}

output "table_stream_arn" {
  description = "The ARN of the table stream (if enabled)"
  value       = try(aws_dynamodb_table.this[0].stream_arn, "")
}

output "table_stream_label" {
  description = "The stream label of the table (if enabled)"
  value       = try(aws_dynamodb_table.this[0].stream_label, "")
}
