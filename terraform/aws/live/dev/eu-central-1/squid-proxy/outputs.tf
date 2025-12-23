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

# =========================================================================
# Auto Scaling Outputs
# =========================================================================

output "autoscaling_enabled" {
  description = "Whether auto-scaling policies are enabled"
  value       = module.squid_proxy.autoscaling_enabled
}

output "scaling_policies_summary" {
  description = "Summary of enabled scaling policies and their target values"
  value       = module.squid_proxy.scaling_policies_summary
}

output "cpu_scaling_policy_arn" {
  description = "ARN of the CPU target tracking scaling policy"
  value       = module.squid_proxy.cpu_scaling_policy_arn
}

output "memory_scaling_policy_arn" {
  description = "ARN of the memory target tracking scaling policy"
  value       = module.squid_proxy.memory_scaling_policy_arn
}
