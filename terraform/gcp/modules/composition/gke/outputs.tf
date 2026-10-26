output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = module.gke.name
}

output "cluster_id" {
  description = "ID of the GKE cluster"
  value       = module.gke.cluster_id
}

output "endpoint" {
  description = "Cluster master endpoint (internal or external depending on enable_private_endpoint)"
  value       = module.gke.endpoint
  sensitive   = true
}

output "ca_certificate" {
  description = "Base64-encoded cluster CA certificate"
  value       = module.gke.ca_certificate
  sensitive   = true
}

output "location" {
  description = "Cluster location (region for regional clusters, zone for zonal)"
  value       = module.gke.region
}

output "service_account" {
  description = "Email of the service account used by cluster nodes"
  value       = module.gke.service_account
}

output "workload_identity_pool" {
  description = "Workload Identity pool, in the form <project_id>.svc.id.goog"
  value       = module.gke.identity_namespace
}

output "node_pools_names" {
  description = "Names of the created node pools"
  value       = module.gke.node_pools_names
}

output "master_version" {
  description = "Current master Kubernetes version"
  value       = module.gke.master_version
}

output "master_egress_firewall_rule_name" {
  description = "Name of the node->control-plane egress firewall rule this module creates (null if create_master_egress_firewall_rule is false, master_ipv4_cidr_block is unset, or node_pools_tags is empty)"
  value       = try(google_compute_firewall.allow_egress_to_master[0].name, null)
}
