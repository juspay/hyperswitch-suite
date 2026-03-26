# ============================================================================
# Load Balancer Outputs
# ============================================================================

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.load_balancer.alb_arn
}

output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = module.load_balancer.alb_id
}

output "alb_name" {
  description = "Name of the Application Load Balancer"
  value       = module.load_balancer.alb_name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.load_balancer.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.load_balancer.alb_zone_id
}

output "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  value       = module.load_balancer.alb_arn_suffix
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ID of the load balancer security group"
  value       = module.load_balancer.security_group_id
}

output "alb_security_group_arn" {
  description = "ARN of the load balancer security group"
  value       = module.load_balancer.security_group_arn
}

# Listener Outputs
output "alb_listener_arns" {
  description = "Map of listener keys to listener ARNs"
  value       = module.load_balancer.listener_arns
}

output "alb_listener_ids" {
  description = "Map of listener keys to listener IDs"
  value       = module.load_balancer.listener_ids
}

# Route53 Outputs
output "alb_route53_zone_id" {
  description = "ID of the Route53 hosted zone"
  value       = module.load_balancer.route53_zone_id
}

output "alb_route53_zone_arn" {
  description = "ARN of the Route53 hosted zone"
  value       = module.load_balancer.route53_zone_arn
}

output "alb_route53_name_servers" {
  description = "Name servers of the created Route53 hosted zone"
  value       = module.load_balancer.route53_name_servers
}

output "alb_route53_record_fqdns" {
  description = "FQDNs of the created Route53 records"
  value       = module.load_balancer.route53_record_fqdns
}
