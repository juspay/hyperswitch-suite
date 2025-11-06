output "route_table_id" {
  description = "The ID of the route table"
  value       = aws_route_table.main.id
}

output "route_table_arn" {
  description = "The ARN of the route table"
  value       = aws_route_table.main.arn
}

output "route_table_owner_id" {
  description = "The ID of the AWS account that owns the route table"
  value       = aws_route_table.main.owner_id
}
