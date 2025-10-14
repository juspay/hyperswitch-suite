output "envoy_nlb_dns_name" {
  description = "DNS name of the Envoy NLB"
  value       = module.envoy_proxy.nlb_dns_name
}

output "envoy_nlb_arn" {
  description = "ARN of the Envoy NLB"
  value       = module.envoy_proxy.nlb_arn
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
