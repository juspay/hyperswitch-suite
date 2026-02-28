output "alb_id" {
  description = "ID of the load balancer"
  value       = try(aws_lb.this[0].id, "")
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = try(aws_lb.this[0].arn, "")
}

output "alb_arn_suffix" {
  description = "ARN suffix for use with CloudWatch Metrics"
  value       = try(aws_lb.this[0].arn_suffix, "")
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = try(aws_lb.this[0].dns_name, "")
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the load balancer"
  value       = try(aws_lb.this[0].zone_id, "")
}

output "alb_name" {
  description = "Name of the load balancer"
  value       = try(aws_lb.this[0].name, "")
}
