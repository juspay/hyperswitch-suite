output "squid_nlb_dns_name" {
  description = "DNS name of the Squid NLB"
  value       = module.squid_proxy.nlb_dns_name
}

output "squid_nlb_arn" {
  description = "ARN of the Squid NLB"
  value       = module.squid_proxy.nlb_arn
}

output "squid_asg_name" {
  description = "Name of the Squid ASG"
  value       = module.squid_proxy.asg_name
}

output "squid_logs_bucket_name" {
  description = "Name of the S3 logs bucket"
  value       = module.squid_proxy.logs_bucket_name
}

output "squid_target_group_arn" {
  description = "ARN of the target group"
  value       = module.squid_proxy.target_group_arn
}
