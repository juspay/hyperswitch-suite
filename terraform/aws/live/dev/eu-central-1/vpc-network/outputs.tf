output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc_network.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc_network.vpc_cidr_block
}

output "external_incoming_subnet_ids" {
  description = "External incoming (public) subnet IDs"
  value       = module.vpc_network.external_incoming_subnet_ids
}

output "management_subnet_ids" {
  description = "Management (public) subnet IDs"
  value       = module.vpc_network.management_subnet_ids
}

output "eks_workers_subnet_ids" {
  description = "EKS workers (private) subnet IDs"
  value       = module.vpc_network.eks_workers_subnet_ids
}

output "eks_control_plane_subnet_ids" {
  description = "EKS control plane subnet IDs"
  value       = module.vpc_network.eks_control_plane_subnet_ids
}

output "incoming_envoy_subnet_ids" {
  description = "Incoming envoy subnet IDs"
  value       = module.vpc_network.incoming_envoy_subnet_ids
}

output "outgoing_proxy_subnet_ids" {
  description = "Outgoing proxy subnet IDs"
  value       = module.vpc_network.outgoing_proxy_subnet_ids
}

output "utils_subnet_ids" {
  description = "Utils subnet IDs"
  value       = module.vpc_network.utils_subnet_ids
}

output "locker_server_subnet_ids" {
  description = "Locker server subnet IDs"
  value       = module.vpc_network.locker_server_subnet_ids
}

output "data_stack_subnet_ids" {
  description = "Data stack subnet IDs"
  value       = module.vpc_network.data_stack_subnet_ids
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = module.vpc_network.database_subnet_ids
}

output "elasticache_subnet_ids" {
  description = "ElastiCache subnet IDs"
  value       = module.vpc_network.elasticache_subnet_ids
}

output "custom_subnet_ids" {
  description = "Custom subnet IDs"
  value       = module.vpc_network.custom_subnet_ids
}

output "nat_gateway_ips" {
  description = "NAT Gateway public IPs"
  value       = module.vpc_network.nat_gateway_public_ips
}
