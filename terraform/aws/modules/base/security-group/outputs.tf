output "sg_id" {
  description = "The ID of the security group"
  value       = aws_security_group.this.id
}

output "sg_arn" {
  description = "The ARN of the security group"
  value       = aws_security_group.this.arn
}

output "sg_name" {
  description = "The name of the security group"
  value       = aws_security_group.this.name
}

output "sg_vpc_id" {
  description = "The VPC ID of the security group"
  value       = aws_security_group.this.vpc_id
}
