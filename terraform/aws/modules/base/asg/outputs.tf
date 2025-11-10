output "asg_id" {
  description = "The Auto Scaling Group ID"
  value       = aws_autoscaling_group.this.id
}

output "asg_name" {
  description = "The Auto Scaling Group name"
  value       = aws_autoscaling_group.this.name
}

output "asg_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.arn
}

output "asg_availability_zones" {
  description = "The availability zones of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.availability_zones
}

output "asg_min_size" {
  description = "The minimum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.min_size
}

output "asg_max_size" {
  description = "The maximum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.max_size
}

output "asg_desired_capacity" {
  description = "The desired capacity of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.desired_capacity
}

# =========================================================================
# Auto Scaling Policy Outputs
# =========================================================================

output "cpu_scaling_policy_arn" {
  description = "ARN of the CPU target tracking scaling policy"
  value       = var.enable_scaling_policies && var.scaling_policies.cpu_target_tracking.enabled ? aws_autoscaling_policy.cpu_target_tracking[0].arn : null
}

output "cpu_scaling_policy_name" {
  description = "Name of the CPU target tracking scaling policy"
  value       = var.enable_scaling_policies && var.scaling_policies.cpu_target_tracking.enabled ? aws_autoscaling_policy.cpu_target_tracking[0].name : null
}

output "memory_scaling_policy_arn" {
  description = "ARN of the memory target tracking scaling policy"
  value       = var.enable_scaling_policies && var.scaling_policies.memory_target_tracking.enabled ? aws_autoscaling_policy.memory_target_tracking[0].arn : null
}

output "memory_scaling_policy_name" {
  description = "Name of the memory target tracking scaling policy"
  value       = var.enable_scaling_policies && var.scaling_policies.memory_target_tracking.enabled ? aws_autoscaling_policy.memory_target_tracking[0].name : null
}
