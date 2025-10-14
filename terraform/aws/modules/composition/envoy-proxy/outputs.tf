output "nlb_arn" {
  description = "ARN of the Network Load Balancer"
  value       = aws_lb.envoy.arn
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.envoy.dns_name
}

output "nlb_zone_id" {
  description = "Zone ID of the Network Load Balancer"
  value       = aws_lb.envoy.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = module.target_group.tg_arn
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
  value       = module.envoy_iam_role.role_arn
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = module.envoy_iam_role.role_name
}
