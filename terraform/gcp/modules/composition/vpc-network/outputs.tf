# Network Outputs

output "network_id" {
  description = "The ID of the VPC network"
  value       = module.vpc_network.network_id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = module.vpc_network.network_name
}

output "network_self_link" {
  description = "The self-link of the VPC network"
  value       = module.vpc_network.network_self_link
}

# Subnet Outputs

output "subnets" {
  description = "Map of created subnets, keyed by region/name, as returned by the network module"
  value       = module.vpc_network.subnets
}

output "subnets_by_tier" {
  description = "Map of subnet self-links keyed by tier name (external-incoming, management, gke-nodes, ...)"
  value = {
    for tier, subnet in local.all_subnets :
    tier => module.vpc_network.subnets["${var.region}/${local.name_prefix}-${tier}"].self_link
    if subnet.cidr != null
  }
}

output "gke_nodes_subnet_self_link" {
  description = "Self-link of the GKE node pool subnet"
  value       = module.vpc_network.subnets["${var.region}/${local.gke_nodes_subnet_name}"].self_link
}

output "gke_pods_secondary_range_name" {
  description = "Name of the GKE pods secondary range, for wiring into composition/gke"
  value       = "${local.name_prefix}-gke-pods"
}

output "gke_services_secondary_range_name" {
  description = "Name of the GKE services secondary range, for wiring into composition/gke"
  value       = "${local.name_prefix}-gke-services"
}

# Cloud Router / Cloud NAT Outputs

output "router_name" {
  description = "Name of the Cloud Router"
  value       = module.cloud_router.router.name
}

output "nat_name" {
  description = "Name of the Cloud NAT gateway"
  value       = module.cloud_nat.name
}

output "nat_ips" {
  description = "Reserved static external IP addresses assigned to Cloud NAT (empty unless nat_static_ip_count > 0). Share these with PSPs/banks for egress IP allowlisting."
  value       = google_compute_address.nat[*].address
}

# Private Service Access Outputs

output "private_service_access_enabled" {
  description = "Whether the Private Service Access peering range/connection was created; downstream Cloud SQL/Memorystore modules should depend_on this module before using it"
  value       = true
}

output "private_service_access_range_name" {
  description = "Name of the reserved PSA IP range - AlloyDB's network_config.allocated_ip_range expects this exact name, not a CIDR. Computed directly (not read from module.private_service_access, which doesn't expose this as an output) - must match module.private_service_access's address_name input exactly."
  value       = "${local.name_prefix}-psa-range"
}

# Private Service Connect for Google APIs Outputs

output "psc_google_apis_ip" {
  description = "Internal IP of the Private Service Connect Google APIs endpoint (null unless enable_psc_google_apis = true)"
  value       = try(module.psc_google_apis[0].private_service_connect_ip, null)
}
