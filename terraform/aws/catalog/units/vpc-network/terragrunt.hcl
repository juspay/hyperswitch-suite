include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/vpc-network?ref=vpc-v0.1.11"
}

inputs = {
  vpc_name     = "${include.root.locals.project_name}-${include.root.locals.environment.short}-vpc"
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true

  map_public_ip_on_launch     = false
  enable_eks_elb_tag          = true
  enable_eks_internal_elb_tag = true

  vpc_cidr = "${values.vpc_cidr_prefix}.0.0/16"

  availability_zones = [
    "${include.root.locals.region}a",
    "${include.root.locals.region}b",
  ]

  secondary_cidr_blocks = []

  single_nat_gateway = try(values.single_nat_gateway, false)

  external_incoming_subnet_cidrs = [
    "${values.vpc_cidr_prefix}.18.0/24",
    "${values.vpc_cidr_prefix}.19.0/24",
  ]

  management_subnet_cidrs = [
    "${values.vpc_cidr_prefix}.10.0/24",
    "${values.vpc_cidr_prefix}.11.0/24",
  ]

  eks_workers_subnet_cidrs = [
    "${values.vpc_cidr_prefix}.0.0/22",
    "${values.vpc_cidr_prefix}.4.0/22",
  ]

  eks_control_plane_subnet_cidrs = [
    "${values.vpc_cidr_prefix}.32.0/24",
    "${values.vpc_cidr_prefix}.33.0/24",
  ]

  database_subnet_cidrs = [
    "${values.vpc_cidr_prefix}.20.0/24",
    "${values.vpc_cidr_prefix}.21.0/24",
  ]

  locker_database_subnet_cidrs = [
    "${values.vpc_cidr_prefix}.12.0/24",
    "${values.vpc_cidr_prefix}.13.0/24",
  ]

  locker_server_subnet_cidrs = [
    "${values.vpc_cidr_prefix}.26.0/24",
    "${values.vpc_cidr_prefix}.27.0/24",
  ]

  elasticache_subnet_cidrs = [
    "${values.vpc_cidr_prefix}.28.0/24",
    "${values.vpc_cidr_prefix}.29.0/24"
  ]

  data_stack_subnet_cidrs = [
    "${values.vpc_cidr_prefix}.16.0/24",
    "${values.vpc_cidr_prefix}.17.0/24"
  ]

  incoming_envoy_subnet_cidrs = [
    "${values.vpc_cidr_prefix}.34.0/24",
    "${values.vpc_cidr_prefix}.35.0/24"
  ]

  outgoing_proxy_subnet_cidrs = [
    "${values.vpc_cidr_prefix}.24.0/24",
    "${values.vpc_cidr_prefix}.25.0/24"
  ]

  utils_subnet_cidrs = [
    "${values.vpc_cidr_prefix}.8.0/24",
    "${values.vpc_cidr_prefix}.9.0/24"
  ]

  lambda_subnet_cidrs = [
    "${values.vpc_cidr_prefix}.97.0/24",
  ]

  enable_vpc_endpoints = true

  create_nacl = true

  gateway_vpc_endpoints = [
    "s3",
    "dynamodb"
  ]

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
    "elasticloadbalancing",
    "autoscaling",
    "monitoring",
    "lambda",
    "sns",
    "sqs",
    "eks",
    "execute_api",
    "efs"
  ]

  custom_interface_vpc_endpoints = try(values.custom_interface_vpc_endpoints, null)

  create_vpc_endpoint_security_group = true
  enable_flow_logs                   = false
  flow_logs_destination_type         = "cloud-watch-logs"
  flow_logs_traffic_type             = "ALL"

  manage_default_network_acl    = true
  manage_default_security_group = true
  manage_default_route_table    = true

  vpc_peering_connections = {}

  enable_vpc_peering_routes = false

  tags = {
    Environment = include.root.locals.environment.short
    Team        = "Infra"
    ManagedBy   = "Terraform"
    Project     = include.root.locals.project_name
  }
}