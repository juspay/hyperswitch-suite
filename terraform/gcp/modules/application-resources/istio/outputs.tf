output "cluster_name" {
  description = "Name of the GKE cluster Istio is installed on"
  value       = var.cluster_name
}

output "gateway_static_ip" {
  description = "Static IP address reserved for the Istio gateway, if enabled"
  value       = var.create_gateway_static_ip ? google_compute_address.gateway[0].address : null
}

output "host_domains_map" {
  description = "Passthrough of var.host_domains"
  value       = var.host_domains
}
