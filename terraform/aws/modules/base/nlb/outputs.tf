output "nlb_id" {
  description = "ID of the network load balancer"
  value       = aws_lb.this.id
}

output "nlb_arn" {
  description = "ARN of the network load balancer"
  value       = aws_lb.this.arn
}

output "nlb_arn_suffix" {
  description = "ARN suffix for use with CloudWatch Metrics"
  value       = aws_lb.this.arn_suffix
}

output "nlb_dns_name" {
  description = "DNS name of the network load balancer"
  value       = aws_lb.this.dns_name
}

output "nlb_zone_id" {
  description = "Canonical hosted zone ID of the network load balancer"
  value       = aws_lb.this.zone_id
}

output "nlb_name" {
  description = "Name of the network load balancer"
  value       = aws_lb.this.name
}
