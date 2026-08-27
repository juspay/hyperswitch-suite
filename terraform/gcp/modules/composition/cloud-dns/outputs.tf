output "zone_name" {
  description = "Name of the managed zone"
  value       = module.cloud_dns.name
}

output "domain" {
  description = "Domain of the zone"
  value       = module.cloud_dns.domain
}

output "name_servers" {
  description = "Name servers assigned to the zone (only meaningful for public zones)"
  value       = module.cloud_dns.name_servers
}

output "type" {
  description = "Type of the zone"
  value       = module.cloud_dns.type
}
