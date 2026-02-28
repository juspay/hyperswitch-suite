output "tg_id" {
  description = "The ID of the target group"
  value       = try(aws_lb_target_group.this[0].id, "")
}

output "tg_arn" {
  description = "The ARN of the target group"
  value       = try(aws_lb_target_group.this[0].arn, "")
}

output "tg_arn_suffix" {
  description = "The ARN suffix for use with CloudWatch metrics"
  value       = try(aws_lb_target_group.this[0].arn_suffix, "")
}

output "tg_name" {
  description = "The name of the target group"
  value       = try(aws_lb_target_group.this[0].name, "")
}

output "tg_port" {
  description = "The port of the target group"
  value       = try(aws_lb_target_group.this[0].port, null)
}

output "tg_protocol" {
  description = "The protocol of the target group"
  value       = try(aws_lb_target_group.this[0].protocol, "")
}
