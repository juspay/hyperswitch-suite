# =========================================================================
# LOAD BALANCER OUTPUTS
# =========================================================================
output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = var.create_alb ? aws_lb.this[0].arn : null
}

output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = var.create_alb ? aws_lb.this[0].id : null
}

output "alb_name" {
  description = "Name of the Application Load Balancer"
  value       = var.create_alb ? aws_lb.this[0].name : null
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = var.create_alb ? aws_lb.this[0].dns_name : null
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = var.create_alb ? aws_lb.this[0].zone_id : null
}

output "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer (useful for CloudWatch metrics)"
  value       = var.create_alb ? aws_lb.this[0].arn_suffix : null
}

output "alb_tags_all" {
  description = "Map of tags assigned to the Load Balancer"
  value       = var.create_alb ? aws_lb.this[0].tags_all : null
}

# =========================================================================
# SECURITY GROUP OUTPUTS
# =========================================================================
output "security_group_id" {
  description = "ID of the load balancer security group"
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "ARN of the load balancer security group"
  value       = aws_security_group.this.arn
}

# =========================================================================
# LISTENER OUTPUTS
# =========================================================================
output "listener_arns" {
  description = "Map of listener keys to listener ARNs"
  value       = var.create_alb ? { for key, listener in aws_lb_listener.this : key => listener.arn } : {}
}

output "listener_ids" {
  description = "Map of listener keys to listener IDs"
  value       = var.create_alb ? { for key, listener in aws_lb_listener.this : key => listener.id } : {}
}

output "listener_details" {
  description = "Map of listener keys with port and protocol details"
  value = var.create_alb ? { for key, listener in var.listeners : key => {
    port     = listener.port
    protocol = listener.protocol
  } } : {}
}

# =========================================================================
# ROUTE53 ZONE OUTPUTS
# =========================================================================
output "route53_zone_id" {
  description = "ID of the Route53 hosted zone (if created)"
  value       = var.route53_zone.create ? aws_route53_zone.this[0].zone_id : var.route53_zone.zone_id
}

output "route53_zone_arn" {
  description = "ARN of the Route53 hosted zone (if created)"
  value       = var.route53_zone.create ? aws_route53_zone.this[0].arn : null
}

output "route53_name_servers" {
  description = "Name servers of the created Route53 hosted zone (for delegation)"
  value       = var.route53_zone.create ? aws_route53_zone.this[0].name_servers : null
}

output "route53_record_fqdns" {
  description = "FQDNs of the created Route53 records"
  value       = var.create_alb ? { for key, record in aws_route53_record.alb : key => record.fqdn } : {}
}

output "route53_zone_name" {
  description = "Name of the Route53 hosted zone (if created)"
  value       = var.route53_zone.create ? aws_route53_zone.this[0].name : null
}

output "route53_record_names" {
  description = "Names of the created Route53 records"
  value       = var.create_alb ? { for key, record in aws_route53_record.alb : key => record.name } : {}
}
