output "table_id" {
  description = "The ID (name) of the table"
  value       = aws_dynamodb_table.this.id
}

output "table_name" {
  description = "The name of the table"
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "The ARN of the table"
  value       = aws_dynamodb_table.this.arn
}

output "table_stream_arn" {
  description = "The ARN of the table stream (if enabled)"
  value       = aws_dynamodb_table.this.stream_arn
}

output "table_stream_label" {
  description = "The stream label of the table (if enabled)"
  value       = aws_dynamodb_table.this.stream_label
}
