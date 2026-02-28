###################
# VPC
###################
module "vpc" {
  source = "../../base/vpc"

  create   = var.create
  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_cidr

  secondary_cidr_blocks = var.secondary_cidr_blocks

  enable_dns_hostnames                 = var.enable_dns_hostnames
  enable_dns_support                   = var.enable_dns_support
  enable_network_address_usage_metrics = var.enable_network_address_usage_metrics

  instance_tenancy = var.instance_tenancy
  enable_ipv6      = var.enable_ipv6

  create_internet_gateway = var.create_internet_gateway
  enable_nat_gateway      = var.enable_nat_gateway
  nat_gateway_count       = var.single_nat_gateway ? 1 : length(var.availability_zones)

  manage_default_network_acl      = var.manage_default_network_acl
  manage_default_security_group   = var.manage_default_security_group
  manage_default_route_table      = var.manage_default_route_table

  enable_flow_logs            = var.enable_flow_logs
  flow_logs_iam_role_arn      = var.flow_logs_iam_role_arn
  flow_logs_destination_arn   = var.flow_logs_destination_arn
  flow_logs_destination_type  = var.flow_logs_destination_type
  flow_logs_traffic_type      = var.flow_logs_traffic_type
  flow_logs_log_format        = var.flow_logs_log_format

  create_dhcp_options              = var.create_dhcp_options
  dhcp_options_domain_name         = var.dhcp_options_domain_name
  dhcp_options_domain_name_servers = var.dhcp_options_domain_name_servers
  dhcp_options_ntp_servers         = var.dhcp_options_ntp_servers

  tags = var.tags
}

###################
# External Incoming Subnets (Public - for ALB, NAT Gateway)
###################
module "external_incoming_subnets" {
  source = "../../base/subnet"
  count  = length(var.external_incoming_subnet_cidrs)

  vpc_id            = module.vpc.vpc_id
  subnet_name       = "${var.vpc_name}-external-incoming-${var.availability_zones[count.index]}"
  cidr_block        = var.external_incoming_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  subnet_tier = "external-incoming"
  subnet_type = "public"

  map_public_ip_on_launch = var.map_public_ip_on_launch  # Should be false per security model

  # Route table is managed by shared route tables (route-tables.tf)
  create_route_table = false

  # Create NAT Gateway in external incoming subnets
  create_nat_gateway            = var.enable_nat_gateway && !var.single_nat_gateway ? true : (count.index == 0 ? true : false)
  nat_gateway_eip_allocation_id = var.enable_nat_gateway && !var.single_nat_gateway ? module.vpc.nat_eip_allocation_ids[count.index] : (count.index == 0 ? module.vpc.nat_eip_allocation_ids[0] : "")

  tags = merge(
    var.tags,
    var.external_incoming_subnet_tags,
    {
      "Tier"                   = "external-incoming"
      "kubernetes.io/role/elb" = var.enable_eks_elb_tag ? "1" : null
    }
  )
}

###################
# Management Subnets (Public - for Bastion with Elastic IP)
###################
module "management_subnets" {
  source = "../../base/subnet"
  count  = length(var.management_subnet_cidrs)

  vpc_id            = module.vpc.vpc_id
  subnet_name       = "${var.vpc_name}-management-${var.availability_zones[count.index]}"
  cidr_block        = var.management_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  subnet_tier = "management"
  subnet_type = "public"

  map_public_ip_on_launch = var.map_public_ip_on_launch  # Should be false - use Elastic IP for bastion

  # Route table is managed by shared route tables (route-tables.tf)
  create_route_table = false

  tags = merge(
    var.tags,
    var.management_subnet_tags,
    {
      "Tier" = "management"
    }
  )
}

###################
# EKS Worker Node Subnets (Private with NAT Gateway access - /21 for ~2000 IPs)
###################
module "eks_workers_subnets" {
  source = "../../base/subnet"
  count  = length(var.eks_workers_subnet_cidrs)

  vpc_id            = module.vpc.vpc_id
  subnet_name       = "${var.vpc_name}-eks-workers-${var.availability_zones[count.index]}"
  cidr_block        = var.eks_workers_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  subnet_tier = "eks-workers"
  subnet_type = "private-isolated"

  # Route table is managed by shared route tables (route-tables.tf)
  create_route_table = false

  tags = merge(
    var.tags,
    var.eks_workers_subnet_tags,
    {
      "Tier"                            = "eks-workers"
      "kubernetes.io/role/internal-elb" = var.enable_eks_internal_elb_tag ? "1" : null
    }
  )
}

###################
# EKS Control Plane Subnets (Private Isolated)
###################
module "eks_control_plane_subnets" {
  source = "../../base/subnet"
  count  = length(var.eks_control_plane_subnet_cidrs)

  vpc_id            = module.vpc.vpc_id
  subnet_name       = "${var.vpc_name}-eks-control-plane-${var.availability_zones[count.index]}"
  cidr_block        = var.eks_control_plane_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  subnet_tier = "eks-control-plane"
  subnet_type = "private-isolated"

  # Route table is managed by shared route tables (route-tables.tf)
  create_route_table = false

  tags = merge(
    var.tags,
    var.eks_control_plane_subnet_tags,
    {
      "Tier" = "eks-control-plane"
    }
  )
}

###################
# Database Subnets (Fully Isolated - no internet)
###################
module "database_subnets" {
  source = "../../base/subnet"
  count  = length(var.database_subnet_cidrs)

  vpc_id            = module.vpc.vpc_id
  subnet_name       = "${var.vpc_name}-database-${var.availability_zones[count.index]}"
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  subnet_tier = "database"
  subnet_type = "private-isolated"

  # Route table is managed by shared route tables (route-tables.tf)
  create_route_table = false

  tags = merge(
    var.tags,
    var.database_subnet_tags,
    {
      "Tier" = "database"
    }
  )
}

###################
# Locker Database Subnets (PCI-DSS - Fully Isolated)
###################
module "locker_database_subnets" {
  source = "../../base/subnet"
  count  = length(var.locker_database_subnet_cidrs)

  vpc_id            = module.vpc.vpc_id
  subnet_name       = "${var.vpc_name}-locker-database-${var.availability_zones[count.index]}"
  cidr_block        = var.locker_database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  subnet_tier = "locker-database"
  subnet_type = "private-isolated"

  # Route table is managed by shared route tables (route-tables.tf)
  create_route_table = false

  tags = merge(
    var.tags,
    var.locker_database_subnet_tags,
    {
      "Tier"       = "locker-database"
      "Compliance" = "PCI-DSS"
    }
  )
}

###################
# Locker Server Subnets (PCI-DSS - Fully Isolated)
###################
module "locker_server_subnets" {
  source = "../../base/subnet"
  count  = length(var.locker_server_subnet_cidrs)

  vpc_id            = module.vpc.vpc_id
  subnet_name       = "${var.vpc_name}-locker-server-${var.availability_zones[count.index]}"
  cidr_block        = var.locker_server_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  subnet_tier = "locker-server"
  subnet_type = "private-isolated"

  # Route table is managed by shared route tables (route-tables.tf)
  create_route_table = false

  tags = merge(
    var.tags,
    var.locker_server_subnet_tags,
    {
      "Tier"       = "locker-server"
      "Compliance" = "PCI-DSS"
    }
  )
}

###################
# ElastiCache Subnets (Fully Isolated)
###################
module "elasticache_subnets" {
  source = "../../base/subnet"
  count  = length(var.elasticache_subnet_cidrs)

  vpc_id            = module.vpc.vpc_id
  subnet_name       = "${var.vpc_name}-elasticache-${var.availability_zones[count.index]}"
  cidr_block        = var.elasticache_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  subnet_tier = "elasticache"
  subnet_type = "private-isolated"

  # Route table is managed by shared route tables (route-tables.tf)
  create_route_table = false

  tags = merge(
    var.tags,
    var.elasticache_subnet_tags,
    {
      "Tier" = "elasticache"
    }
  )
}

###################
# Data Stack Subnets (S3 Endpoint Only)
###################
module "data_stack_subnets" {
  source = "../../base/subnet"
  count  = length(var.data_stack_subnet_cidrs)

  vpc_id            = module.vpc.vpc_id
  subnet_name       = "${var.vpc_name}-data-stack-${var.availability_zones[count.index]}"
  cidr_block        = var.data_stack_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  subnet_tier = "data-stack"
  subnet_type = "private-isolated"

  # Route table is managed by shared route tables (route-tables.tf)
  create_route_table = false

  tags = merge(
    var.tags,
    var.data_stack_subnet_tags,
    {
      "Tier" = "data-stack"
    }
  )
}

###################
# Incoming Web Envoy Subnets (Private with NAT)
###################
module "incoming_envoy_subnets" {
  source = "../../base/subnet"
  count  = length(var.incoming_envoy_subnet_cidrs)

  vpc_id            = module.vpc.vpc_id
  subnet_name       = "${var.vpc_name}-incoming-envoy-${var.availability_zones[count.index]}"
  cidr_block        = var.incoming_envoy_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  subnet_tier = "incoming-envoy"
  subnet_type = "private-isolated"

  # Route table is managed by shared route tables (route-tables.tf)
  create_route_table = false

  tags = merge(
    var.tags,
    var.incoming_envoy_subnet_tags,
    {
      "Tier" = "incoming-envoy"
    }
  )
}

###################
# Outgoing Proxy Subnets (Private with NAT)
###################
module "outgoing_proxy_subnets" {
  source = "../../base/subnet"
  count  = length(var.outgoing_proxy_subnet_cidrs)

  vpc_id            = module.vpc.vpc_id
  subnet_name       = "${var.vpc_name}-outgoing-proxy-${var.availability_zones[count.index]}"
  cidr_block        = var.outgoing_proxy_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  subnet_tier = "outgoing-proxy"
  subnet_type = "private-nat"

  # Route table is managed by shared route tables (route-tables.tf)
  create_route_table = false

  tags = merge(
    var.tags,
    var.outgoing_proxy_subnet_tags,
    {
      "Tier" = "outgoing-proxy"
    }
  )
}

###################
# Utils Subnets (Lambda, Elasticsearch - Private with NAT)
###################
module "utils_subnets" {
  source = "../../base/subnet"
  count  = length(var.utils_subnet_cidrs)

  vpc_id            = module.vpc.vpc_id
  subnet_name       = "${var.vpc_name}-utils-${var.availability_zones[count.index]}"
  cidr_block        = var.utils_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  subnet_tier = "utils"
  subnet_type = "private-isolated"

  # Route table is managed by shared route tables (route-tables.tf)
  create_route_table = false

  tags = merge(
    var.tags,
    var.utils_subnet_tags,
    {
      "Tier" = "utils"
    }
  )
}

###################
# Lambda Subnets (Private with NAT and S3 endpoint access)
###################
module "lambda_subnets" {
  source = "../../base/subnet"
  count  = length(var.lambda_subnet_cidrs)

  vpc_id            = module.vpc.vpc_id
  subnet_name       = "${var.vpc_name}-lambda-${var.availability_zones[count.index]}"
  cidr_block        = var.lambda_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  subnet_tier = "lambda"
  subnet_type = "private-nat"

  # Route table is managed by shared route tables (route-tables.tf)
  create_route_table = false

  tags = merge(
    var.tags,
    var.lambda_subnet_tags,
    {
      "Tier" = "lambda"
    }
  )
}

###################
# Additional Custom Subnet Groups
###################
module "custom_subnets" {
  source   = "../../base/subnet"
  for_each = var.custom_subnet_groups

  vpc_id            = module.vpc.vpc_id
  subnet_name       = "${var.vpc_name}-${each.key}-${each.value.availability_zone}"
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  subnet_tier = each.value.tier
  subnet_type = each.value.type

  create_route_table            = lookup(each.value, "create_route_table", true)
  create_internet_gateway_route = lookup(each.value, "create_igw_route", false)
  internet_gateway_id           = lookup(each.value, "create_igw_route", false) ? module.vpc.internet_gateway_id : ""

  create_nat_gateway_route = lookup(each.value, "create_nat_route", false)
  nat_gateway_id          = lookup(each.value, "create_nat_route", false) ? (var.single_nat_gateway ? module.external_incoming_subnets[0].nat_gateway_id : module.external_incoming_subnets[index(var.availability_zones, each.value.availability_zone)].nat_gateway_id) : ""

  tags = merge(
    var.tags,
    lookup(each.value, "tags", {})
  )
}
