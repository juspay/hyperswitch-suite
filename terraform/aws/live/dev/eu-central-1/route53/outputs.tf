# ============================================================================
# Route53 Outputs
# ============================================================================

output "route53_zone_ids" {
  description = "Map of zone names to zone IDs"
  value       = module.route53.zone_ids
}

output "route53_zone_arns" {
  description = "Map of zone names to zone ARNs"
  value       = module.route53.zone_arns
}

output "route53_name_servers" {
  description = "Map of zone names to list of name servers"
  value       = module.route53.name_servers
}

output "route53_zone_ids_by_name" {
  description = "Map of zone domain names to zone IDs"
  value       = module.route53.zone_ids_by_name
}

output "route53_record_fqdns" {
  description = "Map of record keys to FQDNs"
  value       = module.route53.record_fqdns
}

output "route53_record_names" {
  description = "Map of record keys to record names"
  value       = module.route53.record_names
}

output "route53_summary" {
  description = "Summary of Route53 zones and records created"
  value       = module.route53.summary
}
