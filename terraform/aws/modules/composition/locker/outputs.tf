output "instance_id" {
  description = "ID of the locker instance"
  value       = module.locker_instance.id
}

output "instance_private_ip" {
  description = "Private IP address of the locker instance"
  value       = module.locker_instance.private_ip
}

output "instance_arn" {
  description = "ARN of the locker instance"
  value       = module.locker_instance.arn
}

output "security_group_id" {
  description = "Security group ID of the locker instance"
  value       = local.locker_security_group_id
}

output "subnet_id" {
  description = "Subnet ID where the locker instance is deployed"
  value       = local.locker_subnet_id
}

output "key_name" {
  description = "SSH key pair name used for the locker instance"
  value       = local.key_name
}

output "ssh_private_key_ssm_parameter" {
  description = "SSM Parameter Store path where the auto-generated SSH private key is stored (only populated if key pair was auto-generated)"
  value       = var.create_key_pair && var.public_key == null ? aws_ssm_parameter.locker_private_key[0].name : null
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.locker_nlb.dns_name
}