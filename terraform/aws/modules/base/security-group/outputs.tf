output "sg_id" {
  description = "The ID of the security group"
  value       = try(aws_security_group.this[0].id, "")
}

output "sg_arn" {
  description = "The ARN of the security group"
  value       = try(aws_security_group.this[0].arn, "")
}

output "sg_name" {
  description = "The name of the security group"
  value       = try(aws_security_group.this[0].name, "")
}

output "sg_vpc_id" {
  description = "The VPC ID of the security group"
  value       = try(aws_security_group.this[0].vpc_id, "")
}
