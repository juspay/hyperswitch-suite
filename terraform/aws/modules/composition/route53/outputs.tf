# ============================================================================
# Route53 Zone Outputs
# ============================================================================
output "zone_ids" {
  description = "Map of zone names to zone IDs"
  value       = { for k, v in aws_route53_zone.this : k => v.zone_id }
}

output "zone_arns" {
  description = "Map of zone names to zone ARNs"
  value       = { for k, v in aws_route53_zone.this : k => v.arn }
}

output "name_servers" {
  description = "Map of zone names to list of name servers"
  value       = { for k, v in aws_route53_zone.this : k => v.name_servers }
}

output "zone_ids_by_name" {
  description = "Map of zone names to zone IDs"
  value       = { for k, v in aws_route53_zone.this : v.name => v.zone_id }
}

# ============================================================================
# Route53 Record Outputs
# ============================================================================
output "record_fqdns" {
  description = "Map of record keys to FQDNs"
  value       = { for k, v in aws_route53_record.this : k => v.fqdn }
}

output "record_names" {
  description = "Map of record keys to record names"
  value       = { for k, v in aws_route53_record.this : k => v.name }
}

# ============================================================================
# Summary Output
# ============================================================================
output "summary" {
  description = "Summary of Route53 zones and records created"
  value = {
    for k, v in aws_route53_zone.this : k => {
      zone_id      = v.zone_id
      arn          = v.arn
      name         = v.name
      name_servers = v.name_servers
      records = {
        for record_key, record in aws_route53_record.this : record_key => {
          name = record.name
          type = record.type
          fqdn = record.fqdn
        }
        if startswith(record_key, "${k}_")
      }
    }
  }
}
