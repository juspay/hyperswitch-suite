output "nlb_arn" {
  description = "ARN of the Network Load Balancer"
  value       = var.create_nlb ? aws_lb.squid[0].arn : var.existing_lb_arn
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = var.create_nlb ? aws_lb.squid[0].dns_name : null
}

output "nlb_zone_id" {
  description = "Zone ID of the Network Load Balancer"
  value       = var.create_nlb ? aws_lb.squid[0].zone_id : null
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = var.create_target_group ? module.target_group[0].tg_arn : var.existing_tg_arn
}

output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = module.asg.asg_id
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.asg.asg_name
}

output "asg_security_group_id" {
  description = "Security group ID for ASG instances"
  value       = module.asg_security_group.sg_id
}

output "lb_security_group_id" {
  description = "Security group ID for load balancer"
  value       = module.lb_security_group.sg_id
}

output "logs_bucket_name" {
  description = "Name of the S3 bucket for logs"
  value       = module.logs_bucket.bucket_id
}

output "logs_bucket_arn" {
  description = "ARN of the S3 bucket for logs"
  value       = module.logs_bucket.bucket_arn
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = module.squid_iam_role.role_arn
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = module.squid_iam_role.role_name
}
