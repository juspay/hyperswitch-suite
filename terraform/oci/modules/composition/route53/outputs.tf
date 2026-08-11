output "zone_ids" {
  value = { for k, v in oci_dns_zone.this : k => v.id }
}

output "zone_name_servers" {
  value = { for k, v in oci_dns_zone.this : k => v.nameservers }
}
