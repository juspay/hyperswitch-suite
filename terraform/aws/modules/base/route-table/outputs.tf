output "route_table_id" {
  description = "The ID of the route table"
  value       = try(aws_route_table.main[0].id, "")
}

output "route_table_arn" {
  description = "The ARN of the route table"
  value       = try(aws_route_table.main[0].arn, "")
}

output "route_table_owner_id" {
  description = "The ID of the AWS account that owns the route table"
  value       = try(aws_route_table.main[0].owner_id, "")
}
