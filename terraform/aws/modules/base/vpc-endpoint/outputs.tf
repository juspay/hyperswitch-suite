output "vpc_endpoint_id" {
  description = "The ID of the VPC endpoint"
  value       = try(aws_vpc_endpoint.main[0].id, "")
}

output "vpc_endpoint_arn" {
  description = "The ARN of the VPC endpoint"
  value       = try(aws_vpc_endpoint.main[0].arn, "")
}

output "vpc_endpoint_state" {
  description = "The state of the VPC endpoint"
  value       = try(aws_vpc_endpoint.main[0].state, "")
}

output "vpc_endpoint_dns_entries" {
  description = "The DNS entries for the VPC endpoint"
  value       = try(aws_vpc_endpoint.main[0].dns_entry, [])
}

output "vpc_endpoint_network_interface_ids" {
  description = "One or more network interfaces for the VPC endpoint"
  value       = try(aws_vpc_endpoint.main[0].network_interface_ids, [])
}

output "vpc_endpoint_owner_id" {
  description = "The ID of the AWS account that owns the VPC endpoint"
  value       = try(aws_vpc_endpoint.main[0].owner_id, "")
}

output "security_group_id" {
  description = "The ID of the security group created for the endpoint"
  value       = var.create ? try(aws_security_group.endpoint[0].id, "") : ""
}

output "security_group_arn" {
  description = "The ARN of the security group created for the endpoint"
  value       = var.create ? try(aws_security_group.endpoint[0].arn, "") : ""
}
