include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../modules/composition/vpc-network"
}

inputs = {
  vpc_name           = "${include.root.locals.project_name}-${include.root.locals.environment.short}-vpc"
  vpc_cidr           = include.root.locals.vpc_cidr
  region             = include.root.locals.region
  availability_zones = include.root.locals.availability_zones

  secondary_cidr_blocks = []

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = false

  map_public_ip_on_launch     = false
  enable_eks_elb_tag          = true
  enable_eks_internal_elb_tag = true

  external_incoming_subnet_cidrs = ["10.0.64.0/24", "10.0.65.0/24", "10.0.66.0/24"]
  management_subnet_cidrs        = ["10.0.67.0/24", "10.0.68.0/24", "10.0.69.0/24"]

  eks_workers_subnet_cidrs    = ["10.0.32.0/21", "10.0.40.0/21", "10.0.48.0/21"]
  incoming_envoy_subnet_cidrs = ["10.0.88.0/24", "10.0.89.0/24", "10.0.90.0/24"]
  outgoing_proxy_subnet_cidrs = ["10.0.91.0/24", "10.0.92.0/24", "10.0.93.0/24"]
  utils_subnet_cidrs          = ["10.0.94.0/24", "10.0.95.0/24", "10.0.96.0/24"]
  lambda_subnet_cidrs         = ["10.0.97.0/24", "10.0.98.0/24", "10.0.99.0/24"]

  eks_control_plane_subnet_cidrs = ["10.0.70.0/24", "10.0.71.0/24", "10.0.72.0/24"]
  database_subnet_cidrs          = ["10.0.73.0/24", "10.0.74.0/24", "10.0.75.0/24"]
  locker_database_subnet_cidrs   = ["10.0.76.0/24", "10.0.77.0/24", "10.0.78.0/24"]
  locker_server_subnet_cidrs     = ["10.0.79.0/24", "10.0.80.0/24", "10.0.81.0/24"]
  elasticache_subnet_cidrs       = ["10.0.82.0/24", "10.0.83.0/24", "10.0.84.0/24"]
  data_stack_subnet_cidrs        = ["10.0.85.0/24", "10.0.86.0/24", "10.0.87.0/24"]

  create_nacl = true

  gateway_vpc_endpoints = ["s3", "dynamodb"]

  interface_vpc_endpoints = [
    "ec2",
    "ecr_api",
    "ecr_dkr",
    "logs",
    "secretsmanager",
    "ssm",
    "ssmmessages",
    "sts",
    "ec2messages",
    "kms",
    "eks",
    "eks_auth",
  ]

  create_vpc_endpoint_security_group = true

  enable_flow_logs           = false
  flow_logs_destination_arn  = null
  flow_logs_destination_type = "cloud-watch-logs"
  flow_logs_traffic_type     = "ALL"

  manage_default_network_acl    = true
  manage_default_security_group = true
  manage_default_route_table    = true

  vpc_peering_connections          = {}
  vpc_peering_accepter_connections = {}
  enable_vpc_peering_routes        = true

  tags = merge(
    include.root.locals.tags,
    {
      Environment = include.root.locals.environment.full
      ManagedBy   = "Terraform"
      Project     = include.root.locals.project_name
    }
  )
}
