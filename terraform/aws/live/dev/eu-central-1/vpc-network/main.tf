# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
}

# Compute dynamic VPC name based on project and environment
locals {
  vpc_name = "${var.project_name}-${var.environment}-vpc"
}

module "vpc_network" {
  source = "../../../../modules/composition/vpc-network"

  vpc_name           = local.vpc_name
  vpc_cidr           = var.vpc_cidr
  aws_region         = var.aws_region
  availability_zones = var.availability_zones

  # Secondary CIDRs for EKS pod networking (optional)
  secondary_cidr_blocks = var.secondary_cidr_blocks

  # Enable DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # NAT Gateway configuration
  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway # Set to true for dev to save costs

  # Security Model: NO automatic public IP assignment
  map_public_ip_on_launch     = false # Use Elastic IP for bastion only
  enable_eks_elb_tag          = true
  enable_eks_internal_elb_tag = true

  # External Incoming subnets (Public - for ALB, NAT Gateway)
  external_incoming_subnet_cidrs = var.external_incoming_subnet_cidrs

  # Management subnets (Public - for Bastion with Elastic IP)
  management_subnet_cidrs = var.management_subnet_cidrs

  # EKS Worker Node subnets (Private with NAT - /21 for ~2000 IPs per AZ)
  eks_workers_subnet_cidrs = var.eks_workers_subnet_cidrs

  # EKS Control Plane subnets (Private Isolated)
  eks_control_plane_subnet_cidrs = var.eks_control_plane_subnet_cidrs

  # Database subnets (Fully Isolated - no internet)
  database_subnet_cidrs = var.database_subnet_cidrs

  # Locker Database subnets (PCI-DSS - Fully Isolated)
  locker_database_subnet_cidrs = var.locker_database_subnet_cidrs

  # Locker Server subnets (PCI-DSS - Fully Isolated)
  locker_server_subnet_cidrs = var.locker_server_subnet_cidrs

  # ElastiCache subnets (Fully Isolated)
  elasticache_subnet_cidrs = var.elasticache_subnet_cidrs

  # Data Stack subnets (S3 Endpoint Only)
  data_stack_subnet_cidrs = var.data_stack_subnet_cidrs

  # Incoming Web Envoy subnets (Private with NAT)
  incoming_envoy_subnet_cidrs = var.incoming_envoy_subnet_cidrs

  # Outgoing Proxy subnets (Private with NAT)
  outgoing_proxy_subnet_cidrs = var.outgoing_proxy_subnet_cidrs

  # Utils subnets (Lambda, Elasticsearch - Private with NAT)
  utils_subnet_cidrs = var.utils_subnet_cidrs

  # Network ACL (simplified - allow all traffic like integration environment)
  create_nacl = true

  # VPC Endpoints (save NAT Gateway costs)
  gateway_vpc_endpoints = [
    "s3",
    "dynamodb"
  ]

  interface_vpc_endpoints = var.enable_vpc_endpoints ? [
    "ec2",
    "ecr_api",
    "ecr_dkr",
    "logs",
    "secretsmanager",
    "ssm",
    "ssmmessages",
    "ec2messages",
    "kms"
  ] : []

  create_vpc_endpoint_security_group = true

  # VPC Flow Logs for security monitoring
  enable_flow_logs           = var.enable_flow_logs
  flow_logs_destination_arn  = var.flow_logs_destination_arn
  flow_logs_destination_type = var.flow_logs_destination_type
  flow_logs_traffic_type     = "ALL"

  # Default resource management
  manage_default_network_acl    = true
  manage_default_security_group = true
  manage_default_route_table    = true

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  )
}
