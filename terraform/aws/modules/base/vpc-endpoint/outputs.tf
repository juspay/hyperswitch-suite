output "vpc_endpoint_id" {
  description = "The ID of the VPC endpoint"
  value       = aws_vpc_endpoint.main.id
}

output "vpc_endpoint_arn" {
  description = "The ARN of the VPC endpoint"
  value       = aws_vpc_endpoint.main.arn
}

output "vpc_endpoint_state" {
  description = "The state of the VPC endpoint"
  value       = aws_vpc_endpoint.main.state
}

output "vpc_endpoint_dns_entries" {
  description = "The DNS entries for the VPC endpoint"
  value       = aws_vpc_endpoint.main.dns_entry
}

output "vpc_endpoint_network_interface_ids" {
  description = "One or more network interfaces for the VPC endpoint"
  value       = aws_vpc_endpoint.main.network_interface_ids
}

output "vpc_endpoint_owner_id" {
  description = "The ID of the AWS account that owns the VPC endpoint"
  value       = aws_vpc_endpoint.main.owner_id
}

output "security_group_id" {
  description = "The ID of the security group created for the endpoint"
  value       = try(aws_security_group.endpoint[0].id, "")
}

output "security_group_arn" {
  description = "The ARN of the security group created for the endpoint"
  value       = try(aws_security_group.endpoint[0].arn, "")
}
