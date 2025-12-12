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
  value       = aws_security_group.locker.id
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.locker_nlb.dns_name
}