output "ip_address" {
  description = "Anycast IP address serving this distribution"
  value       = google_compute_global_address.this.address
}

output "url_map_id" {
  description = "ID of the URL map"
  value       = google_compute_url_map.this.id
}

output "backend_bucket_ids" {
  description = "Map of backend bucket key to its resource ID"
  value       = { for k, v in google_compute_backend_bucket.this : k => v.id }
}

output "log_bucket_name" {
  description = "Name of the CDN log bucket, if enabled"
  value       = var.enable_logging ? module.log_bucket[0].name : null
}
