output "tg_id" {
  description = "The ID of the target group"
  value       = aws_lb_target_group.this.id
}

output "tg_arn" {
  description = "The ARN of the target group"
  value       = aws_lb_target_group.this.arn
}

output "tg_arn_suffix" {
  description = "The ARN suffix for use with CloudWatch metrics"
  value       = aws_lb_target_group.this.arn_suffix
}

output "tg_name" {
  description = "The name of the target group"
  value       = aws_lb_target_group.this.name
}

output "tg_port" {
  description = "The port of the target group"
  value       = aws_lb_target_group.this.port
}

output "tg_protocol" {
  description = "The protocol of the target group"
  value       = aws_lb_target_group.this.protocol
}
