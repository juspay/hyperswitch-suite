output "subnet_id" {
  description = "The ID of the subnet"
  value       = aws_subnet.main.id
}

output "subnet_arn" {
  description = "The ARN of the subnet"
  value       = aws_subnet.main.arn
}

output "subnet_cidr_block" {
  description = "The CIDR block of the subnet"
  value       = aws_subnet.main.cidr_block
}

output "subnet_ipv6_cidr_block" {
  description = "The IPv6 CIDR block of the subnet"
  value       = aws_subnet.main.ipv6_cidr_block
}

output "subnet_availability_zone" {
  description = "The AZ of the subnet"
  value       = aws_subnet.main.availability_zone
}

output "subnet_availability_zone_id" {
  description = "The AZ ID of the subnet"
  value       = aws_subnet.main.availability_zone_id
}

output "route_table_id" {
  description = "The ID of the route table"
  value       = var.create_route_table ? aws_route_table.main[0].id : var.route_table_id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = try(aws_nat_gateway.main[0].id, "")
}

output "nat_gateway_public_ip" {
  description = "The public IP address of the NAT Gateway"
  value       = try(aws_nat_gateway.main[0].public_ip, "")
}

output "nat_gateway_private_ip" {
  description = "The private IP address of the NAT Gateway"
  value       = try(aws_nat_gateway.main[0].private_ip, "")
}
