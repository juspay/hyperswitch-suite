###################
# VPC Outputs
###################
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "vpc_secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks of the VPC"
  value       = module.vpc.vpc_secondary_cidr_blocks
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = concat(module.external_incoming_subnets[*].nat_gateway_id)
}

output "nat_gateway_public_ips" {
  description = "List of public IPs of NAT Gateways"
  value       = module.vpc.nat_eip_public_ips
}

###################
# Subnet Outputs
###################

# External Incoming Subnets (Public - ALB, NAT Gateway)
output "external_incoming_subnet_ids" {
  description = "List of IDs of external incoming subnets"
  value       = module.external_incoming_subnets[*].subnet_id
}

output "external_incoming_subnet_cidr_blocks" {
  description = "List of CIDR blocks of external incoming subnets"
  value       = module.external_incoming_subnets[*].subnet_cidr_block
}

# Management Subnets (Public - Bastion)
output "management_subnet_ids" {
  description = "List of IDs of management subnets"
  value       = module.management_subnets[*].subnet_id
}

output "management_subnet_cidr_blocks" {
  description = "List of CIDR blocks of management subnets"
  value       = module.management_subnets[*].subnet_cidr_block
}

# EKS Worker Node Subnets
output "eks_workers_subnet_ids" {
  description = "List of IDs of EKS worker node subnets"
  value       = module.eks_workers_subnets[*].subnet_id
}

output "eks_workers_subnet_cidr_blocks" {
  description = "List of CIDR blocks of EKS worker node subnets"
  value       = module.eks_workers_subnets[*].subnet_cidr_block
}

# EKS Control Plane Subnets
output "eks_control_plane_subnet_ids" {
  description = "List of IDs of EKS control plane subnets"
  value       = module.eks_control_plane_subnets[*].subnet_id
}

output "eks_control_plane_subnet_cidr_blocks" {
  description = "List of CIDR blocks of EKS control plane subnets"
  value       = module.eks_control_plane_subnets[*].subnet_cidr_block
}

output "database_subnet_ids" {
  description = "List of IDs of database subnets"
  value       = module.database_subnets[*].subnet_id
}

output "database_subnet_arns" {
  description = "List of ARNs of database subnets"
  value       = module.database_subnets[*].subnet_arn
}

output "database_subnet_cidr_blocks" {
  description = "List of CIDR blocks of database subnets"
  value       = module.database_subnets[*].subnet_cidr_block
}

# Locker Database Subnets
output "locker_database_subnet_ids" {
  description = "List of IDs of locker database subnets"
  value       = module.locker_database_subnets[*].subnet_id
}

output "locker_database_subnet_cidr_blocks" {
  description = "List of CIDR blocks of locker database subnets"
  value       = module.locker_database_subnets[*].subnet_cidr_block
}

# Locker Server Subnets
output "locker_server_subnet_ids" {
  description = "List of IDs of locker server subnets"
  value       = module.locker_server_subnets[*].subnet_id
}

output "locker_server_subnet_cidr_blocks" {
  description = "List of CIDR blocks of locker server subnets"
  value       = module.locker_server_subnets[*].subnet_cidr_block
}

# ElastiCache Subnets
output "elasticache_subnet_ids" {
  description = "List of IDs of ElastiCache subnets"
  value       = module.elasticache_subnets[*].subnet_id
}

output "elasticache_subnet_cidr_blocks" {
  description = "List of CIDR blocks of ElastiCache subnets"
  value       = module.elasticache_subnets[*].subnet_cidr_block
}

# Data Stack Subnets
output "data_stack_subnet_ids" {
  description = "List of IDs of data stack subnets"
  value       = module.data_stack_subnets[*].subnet_id
}

output "data_stack_subnet_cidr_blocks" {
  description = "List of CIDR blocks of data stack subnets"
  value       = module.data_stack_subnets[*].subnet_cidr_block
}

# Incoming Web Envoy Subnets
output "incoming_envoy_subnet_ids" {
  description = "List of IDs of incoming envoy subnets"
  value       = module.incoming_envoy_subnets[*].subnet_id
}

output "incoming_envoy_subnet_cidr_blocks" {
  description = "List of CIDR blocks of incoming envoy subnets"
  value       = module.incoming_envoy_subnets[*].subnet_cidr_block
}

# Outgoing Proxy Subnets
output "outgoing_proxy_subnet_ids" {
  description = "List of IDs of outgoing proxy subnets"
  value       = module.outgoing_proxy_subnets[*].subnet_id
}

output "outgoing_proxy_subnet_cidr_blocks" {
  description = "List of CIDR blocks of outgoing proxy subnets"
  value       = module.outgoing_proxy_subnets[*].subnet_cidr_block
}

# Utils Subnets
output "utils_subnet_ids" {
  description = "List of IDs of utils subnets"
  value       = module.utils_subnets[*].subnet_id
}

output "utils_subnet_cidr_blocks" {
  description = "List of CIDR blocks of utils subnets"
  value       = module.utils_subnets[*].subnet_cidr_block
}

output "custom_subnet_ids" {
  description = "Map of custom subnet IDs"
  value       = { for k, v in module.custom_subnets : k => v.subnet_id }
}

###################
# Shared Route Table Outputs
###################
output "common_internet_route_table_id" {
  description = "ID of the CommonInternet route table"
  value       = module.common_internet_rt.route_table_id
}

output "common_internet_s3_route_table_id" {
  description = "ID of the CommonInternetS3 route table"
  value       = module.common_internet_s3_rt.route_table_id
}

output "common_local_route_table_id" {
  description = "ID of the CommonLocalRoute route table"
  value       = module.common_local_route_rt.route_table_id
}

output "common_local_s3_route_table_id" {
  description = "ID of the CommonLocalS3 route table"
  value       = module.common_local_s3_rt.route_table_id
}

output "db_route_table_id" {
  description = "ID of the DBRouteTable"
  value       = module.db_route_table.route_table_id
}

output "redis_route_table_id" {
  description = "ID of the RedisRouteTable"
  value       = module.redis_route_table.route_table_id
}

output "database_route_table_id" {
  description = "ID of the Database-RT (locker route table)"
  value       = module.database_route_table.route_table_id
}

output "locker_server_s3_route_table_id" {
  description = "ID of the LockerServerS3 route table"
  value       = module.locker_server_s3_rt.route_table_id
}

output "proxy_peering_nat_a_route_table_id" {
  description = "ID of the ProxyPeeringNAT-A route table"
  value       = var.enable_nat_gateway && length(var.availability_zones) > 0 ? module.proxy_peering_nat_a_rt[0].route_table_id : ""
}

output "proxy_peering_nat_b_route_table_id" {
  description = "ID of the ProxyPeeringNAT-B route table"
  value       = var.enable_nat_gateway && length(var.availability_zones) > 1 ? module.proxy_peering_nat_b_rt[0].route_table_id : ""
}

output "proxy_peering_nat_c_route_table_id" {
  description = "ID of the ProxyPeeringNAT-C route table"
  value       = var.enable_nat_gateway && length(var.availability_zones) > 2 ? module.proxy_peering_nat_c_rt[0].route_table_id : ""
}

output "eks_worker_route_table_id" {
  description = "ID of the EKS worker route table (S3 only, no NAT)"
  value       = module.eks_worker_rt.route_table_id
}

output "common_local_nat_s3_route_table_id" {
  description = "ID of the Common Local NAT S3 route table (NAT + S3 access)"
  value       = var.enable_nat_gateway ? module.common_local_nat_s3_rt[0].route_table_id : ""
}

###################
# Network ACL Outputs
###################
output "nacl_id" {
  description = "ID of the main network ACL"
  value       = try(module.main_nacl[0].nacl_id, "")
}

output "nacl_arn" {
  description = "ARN of the main network ACL"
  value       = try(module.main_nacl[0].nacl_arn, "")
}

###################
# VPC Endpoint Outputs
###################
output "gateway_vpc_endpoint_ids" {
  description = "Map of Gateway VPC Endpoint IDs"
  value       = { for k, v in module.gateway_vpc_endpoints : k => v.vpc_endpoint_id }
}

output "interface_vpc_endpoint_ids" {
  description = "Map of Interface VPC Endpoint IDs"
  value       = { for k, v in module.interface_vpc_endpoints : k => v.vpc_endpoint_id }
}

output "vpc_endpoint_security_group_id" {
  description = "Security group ID for VPC endpoints"
  value       = try(module.vpc_endpoint_sg[0].sg_id, "")
}