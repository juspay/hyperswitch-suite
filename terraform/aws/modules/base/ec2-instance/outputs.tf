output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "The ARN of the EC2 instance"
  value       = aws_instance.this.arn
}

output "instance_state" {
  description = "The state of the EC2 instance"
  value       = aws_instance.this.instance_state
}

output "instance_type" {
  description = "The instance type of the EC2 instance"
  value       = aws_instance.this.instance_type
}

output "private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.this.public_ip
}

output "availability_zone" {
  description = "The availability zone of the EC2 instance"
  value       = aws_instance.this.availability_zone
}

output "primary_network_interface_id" {
  description = "The ID of the primary network interface"
  value       = aws_instance.this.primary_network_interface_id
}

output "subnet_id" {
  description = "The subnet ID where the instance is launched"
  value       = aws_instance.this.subnet_id
}

output "vpc_security_group_ids" {
  description = "The security group IDs attached to the instance"
  value       = aws_instance.this.vpc_security_group_ids
}

output "ssm_session_command" {
  description = "AWS CLI command to start an SSM session"
  value       = "aws ssm start-session --target ${aws_instance.this.id}"
}
