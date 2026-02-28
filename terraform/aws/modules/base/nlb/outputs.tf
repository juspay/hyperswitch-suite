output "nlb_id" {
  description = "ID of the network load balancer"
  value       = try(aws_lb.this[0].id, "")
}

output "nlb_arn" {
  description = "ARN of the network load balancer"
  value       = try(aws_lb.this[0].arn, "")
}

output "nlb_arn_suffix" {
  description = "ARN suffix for use with CloudWatch Metrics"
  value       = try(aws_lb.this[0].arn_suffix, "")
}

output "nlb_dns_name" {
  description = "DNS name of the network load balancer"
  value       = try(aws_lb.this[0].dns_name, "")
}

output "nlb_zone_id" {
  description = "Canonical hosted zone ID of the network load balancer"
  value       = try(aws_lb.this[0].zone_id, "")
}

output "nlb_name" {
  description = "Name of the network load balancer"
  value       = try(aws_lb.this[0].name, "")
}
