output "dns_authorization_records" {
  description = "Map of domain to the DNS record {type, name, data} that must be published (e.g. via composition/cloud-dns) to complete DNS authorization - the equivalent of ACM's validation CNAME"
  value = {
    for domain, auth in google_certificate_manager_dns_authorization.this :
    domain => {
      type = auth.dns_resource_record[0].type
      name = auth.dns_resource_record[0].name
      data = auth.dns_resource_record[0].data
    }
  }
}

output "certificate_ids" {
  description = "Map of certificate key to its Certificate Manager certificate ID"
  value       = { for k, v in google_certificate_manager_certificate.this : k => v.id }
}

output "certificate_map_ids" {
  description = "Map of certificate key to its certificate map ID, for attaching to a target proxy's certificate_map"
  value       = { for k, v in google_certificate_manager_certificate_map.this : k => v.id }
}

output "classic_ssl_certificate_ids" {
  description = "Map of certificate key to its classic google_compute_managed_ssl_certificate ID, for callers using the classic target-proxy ssl_certificates attribute"
  value       = { for k, v in google_compute_managed_ssl_certificate.this : k => v.id }
}
