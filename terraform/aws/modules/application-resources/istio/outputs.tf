# ============================================================================
# Outputs
# ============================================================================

output "lb_security_group_id" {
  description = "ID of the created load balancer security group"
  value       = aws_security_group.lb_security_group[*].id
}

# ALB Outputs
output "alb_id" {
  description = "ID of the Application Load Balancer (if enabled)"
  value       = var.alb.enabled ? module.alb.id : null
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer (if enabled)"
  value       = var.alb.enabled ? module.alb.arn : null
}

output "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer (if enabled)"
  value       = var.alb.enabled ? module.alb.arn_suffix : null
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (if enabled)"
  value       = var.alb.enabled ? module.alb.dns_name : null
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer (if enabled)"
  value       = var.alb.enabled ? module.alb.zone_id : null
}

output "alb_security_group_id" {
  description = "Security group ID of the Application Load Balancer (if enabled)"
  value       = var.alb.enabled ? module.alb.security_group_id : null
}

