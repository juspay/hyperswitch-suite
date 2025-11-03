output "envoy_alb_dns_name" {
  description = "DNS name of the Envoy ALB (null if using existing ALB)"
  value       = module.envoy_proxy.lb_dns_name
}

output "envoy_alb_arn" {
  description = "ARN of the Envoy ALB"
  value       = module.envoy_proxy.lb_arn
}

output "envoy_alb_zone_id" {
  description = "Route53 zone ID of the Envoy ALB (null if using existing ALB)"
  value       = module.envoy_proxy.lb_zone_id
}

output "envoy_asg_name" {
  description = "Name of the Envoy ASG"
  value       = module.envoy_proxy.asg_name
}

output "envoy_logs_bucket_name" {
  description = "Name of the S3 logs bucket"
  value       = module.envoy_proxy.logs_bucket_name
}

output "envoy_target_group_arn" {
  description = "ARN of the target group"
  value       = module.envoy_proxy.target_group_arn
}
