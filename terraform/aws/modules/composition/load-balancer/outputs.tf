# =========================================================================
# LOAD BALANCER OUTPUTS
# =========================================================================
output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.this.id
}

output "alb_name" {
  description = "Name of the Application Load Balancer"
  value       = aws_lb.this.name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.this.zone_id
}

output "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer (useful for CloudWatch metrics)"
  value       = aws_lb.this.arn_suffix
}

output "alb_tags_all" {
  description = "Map of tags assigned to the Load Balancer"
  value       = aws_lb.this.tags_all
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
  value       = { for key, listener in aws_lb_listener.this : key => listener.arn }
}

output "listener_ids" {
  description = "Map of listener keys to listener IDs"
  value       = { for key, listener in aws_lb_listener.this : key => listener.id }
}

output "listener_details" {
  description = "Map of listener keys with port and protocol details"
  value = { for key, listener in var.listeners : key => {
    port     = listener.port
    protocol = listener.protocol
  } }
}

# =========================================================================
# ACM CERTIFICATE OUTPUTS
# =========================================================================
output "certificate_arn" {
  description = "ARN of the ACM certificate (either created or provided)"
  value       = local.certificate_arn
}

output "acm_certificate_arn" {
  description = "ARN of the created ACM certificate (null if using existing cert)"
  value       = local.create_acm_certificate ? module.acm[0].acm_certificate_arn : null
}

output "acm_certificate_domain_validation_options" {
  description = "Domain validation options for the created ACM certificate"
  value       = local.create_acm_certificate ? module.acm[0].acm_certificate_domain_validation_options : null
}

output "acm_certificate_status" {
  description = "Status of the created ACM certificate"
  value       = local.create_acm_certificate ? module.acm[0].acm_certificate_status : null
}

output "validation_route53_record_fqdns" {
  description = "FQDNs of the Route53 validation records created"
  value       = local.create_acm_certificate ? module.acm[0].validation_route53_record_fqdns : null
}

output "distinct_domain_names" {
  description = "Distinct domain names for the certificate"
  value       = local.create_acm_certificate ? module.acm[0].distinct_domain_names : null
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
  value       = { for key, record in aws_route53_record.alb : key => record.fqdn }
}

output "route53_zone_name" {
  description = "Name of the Route53 hosted zone (if created)"
  value       = var.route53_zone.create ? aws_route53_zone.this[0].name : null
}

output "route53_record_names" {
  description = "Names of the created Route53 records"
  value       = { for key, record in aws_route53_record.alb : key => record.name }
}

output "ingress_group_name" {
  description = "Name of the IngressGroup for AWS Load Balancer Controller integration"
  value       = var.ingress_group_name
}
