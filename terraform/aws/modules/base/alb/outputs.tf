output "alb_id" {
  description = "ID of the load balancer"
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.this.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix for use with CloudWatch Metrics"
  value       = aws_lb.this.arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the load balancer"
  value       = aws_lb.this.zone_id
}

output "alb_name" {
  description = "Name of the load balancer"
  value       = aws_lb.this.name
}
