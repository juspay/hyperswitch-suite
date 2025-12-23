output "instance_ids" {
  description = "List of IDs of the locker instances"
  value       = module.locker_instance[*].id
}

output "instance_private_ips" {
  description = "List of private IP addresses of the locker instances"
  value       = module.locker_instance[*].private_ip
}

output "instance_arns" {
  description = "List of ARNs of the locker instances"
  value       = module.locker_instance[*].arn
}

output "locker_port" {
  description = "Port number used for the locker service"
  value       = var.locker_port
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

output "nlb_listener_arns" {
  description = "ARNs of the NLB listeners"
  value       = { for key, listener in aws_lb_listener.locker : key => listener.arn }
}

output "nlb_listener_details" {
  description = "Details of the NLB listeners (port and protocol)"
  value       = { for key, listener in var.nlb_listeners : key => {
    port     = listener.port
    protocol = listener.protocol
  }}
}