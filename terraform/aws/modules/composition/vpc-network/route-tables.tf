###################
# Shared Route Tables (Matching Integration Environment)
###################

# CommonInternet - Main route table for public subnets (Internet Gateway)
module "common_internet_rt" {
  source = "../../base/route-table"

  vpc_id             = module.vpc.vpc_id
  route_table_name   = "${var.vpc_name}-CommonInternet"

  create_internet_gateway_route = true
  internet_gateway_id           = module.vpc.internet_gateway_id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-CommonInternet"
      Type = "public"
    }
  )
}

# CommonInternetS3 - Public subnets with Internet + S3 endpoint
module "common_internet_s3_rt" {
  source = "../../base/route-table"

  vpc_id             = module.vpc.vpc_id
  route_table_name   = "${var.vpc_name}-CommonInternetS3"

  create_internet_gateway_route = true
  internet_gateway_id           = module.vpc.internet_gateway_id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-CommonInternetS3"
      Type = "public-s3"
    }
  )
}

# CommonLocalRoute - Isolated subnets (VPC local only, no internet)
module "common_local_route_rt" {
  source = "../../base/route-table"

  vpc_id             = module.vpc.vpc_id
  route_table_name   = "${var.vpc_name}-CommonLocalRoute"

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-CommonLocalRoute"
      Type = "isolated"
    }
  )
}

# CommonLocalS3 - Isolated subnets with S3 endpoint access
module "common_local_s3_rt" {
  source = "../../base/route-table"

  vpc_id             = module.vpc.vpc_id
  route_table_name   = "${var.vpc_name}-CommonLocalS3"

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-CommonLocalS3"
      Type = "isolated-s3"
    }
  )
}

# DBRouteTable - Database subnets
module "db_route_table" {
  source = "../../base/route-table"

  vpc_id             = module.vpc.vpc_id
  route_table_name   = "${var.vpc_name}-DB-Table"

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-DB-Table"
      Type = "database"
    }
  )
}

# RedisRouteTable - ElastiCache subnets
module "redis_route_table" {
  source = "../../base/route-table"

  vpc_id             = module.vpc.vpc_id
  route_table_name   = "${var.vpc_name}-RedisRouteTable"

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-RedisRouteTable"
      Type = "redis"
    }
  )
}

# Database-RT - Locker subnets (PCI-DSS compliant)
module "database_route_table" {
  source = "../../base/route-table"

  vpc_id             = module.vpc.vpc_id
  route_table_name   = "${var.vpc_name}-Locker-DB-RT"

  tags = merge(
    var.tags,
    {
      Name       = "${var.vpc_name}-Locker-DB-RT"
      Type       = "locker"
      Compliance = "PCI-DSS"
    }
  )
}

# LockerServerS3 - Locker Server subnets with S3 endpoint only (PCI-DSS)
module "locker_server_s3_rt" {
  source = "../../base/route-table"

  vpc_id             = module.vpc.vpc_id
  route_table_name   = "${var.vpc_name}-LockerServerS3"

  tags = merge(
    var.tags,
    {
      Name       = "${var.vpc_name}-LockerServerS3"
      Type       = "locker-s3"
      Compliance = "PCI-DSS"
    }
  )
}

# ProxyPeeringNAT-A - NAT Gateway route for zone A
module "proxy_peering_nat_a_rt" {
  source = "../../base/route-table"
  count  = var.enable_nat_gateway && length(var.availability_zones) > 0 ? 1 : 0

  vpc_id             = module.vpc.vpc_id
  route_table_name   = "${var.vpc_name}-ProxyPeeringNAT-A"

  create_nat_gateway_route = true
  nat_gateway_id           = var.single_nat_gateway ? module.external_incoming_subnets[0].nat_gateway_id : module.external_incoming_subnets[0].nat_gateway_id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-ProxyPeeringNAT-A"
      Type = "private-nat"
      AZ   = var.availability_zones[0]
    }
  )
}

# ProxyPeeringNAT-B - NAT Gateway route for zone B
module "proxy_peering_nat_b_rt" {
  source = "../../base/route-table"
  count  = var.enable_nat_gateway && length(var.availability_zones) > 1 ? 1 : 0

  vpc_id             = module.vpc.vpc_id
  route_table_name   = "${var.vpc_name}-ProxyPeeringNAT-B"

  create_nat_gateway_route = true
  nat_gateway_id           = var.single_nat_gateway ? module.external_incoming_subnets[0].nat_gateway_id : module.external_incoming_subnets[1].nat_gateway_id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-ProxyPeeringNAT-B"
      Type = "private-nat"
      AZ   = var.availability_zones[1]
    }
  )
}

# ProxyPeeringNAT-C - NAT Gateway route for zone C
module "proxy_peering_nat_c_rt" {
  source = "../../base/route-table"
  count  = var.enable_nat_gateway && length(var.availability_zones) > 2 ? 1 : 0

  vpc_id             = module.vpc.vpc_id
  route_table_name   = "${var.vpc_name}-ProxyPeeringNAT-C"

  create_nat_gateway_route = true
  nat_gateway_id           = var.single_nat_gateway ? module.external_incoming_subnets[0].nat_gateway_id : module.external_incoming_subnets[2].nat_gateway_id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-ProxyPeeringNAT-C"
      Type = "private-nat"
      AZ   = var.availability_zones[2]
    }
  )
}


# EKS Worker Route Table - Single route table for all EKS worker subnets (S3 only, no NAT)
module "eks_worker_rt" {
  source = "../../base/route-table"

  vpc_id             = module.vpc.vpc_id
  route_table_name   = "${var.vpc_name}-EKSWorker"

  create_nat_gateway_route = false

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-EKSWorker"
      Type = "eks-worker-s3-only"
    }
  )
}

# Common Local NAT S3 - Private subnets with NAT Gateway and S3 endpoint access
module "common_local_nat_s3_rt" {
  source = "../../base/route-table"
  count  = var.enable_nat_gateway ? 1 : 0

  vpc_id             = module.vpc.vpc_id
  route_table_name   = "${var.vpc_name}-CommonLocalNATS3"

  create_nat_gateway_route = true
  nat_gateway_id           = module.external_incoming_subnets[0].nat_gateway_id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-CommonLocalNATS3"
      Type = "private-nat-s3"
    }
  )
}

###################
# Route Table Associations
###################

# Associate External Incoming subnets with CommonInternet
resource "aws_route_table_association" "external_incoming" {
  count = length(var.external_incoming_subnet_cidrs)

  subnet_id      = module.external_incoming_subnets[count.index].subnet_id
  route_table_id = module.common_internet_rt.route_table_id
}

# Associate Management subnets with CommonInternetS3
resource "aws_route_table_association" "management" {
  count = length(var.management_subnet_cidrs)

  subnet_id      = module.management_subnets[count.index].subnet_id
  route_table_id = module.common_internet_s3_rt.route_table_id
}

# Associate EKS Worker subnets with EKSWorker route table (S3 only, no NAT)
resource "aws_route_table_association" "eks_workers" {
  count = length(var.eks_workers_subnet_cidrs)

  subnet_id      = module.eks_workers_subnets[count.index].subnet_id
  route_table_id = module.eks_worker_rt.route_table_id
}

# Associate EKS Control Plane subnets with CommonLocalRoute
resource "aws_route_table_association" "eks_control_plane" {
  count = length(var.eks_control_plane_subnet_cidrs)

  subnet_id      = module.eks_control_plane_subnets[count.index].subnet_id
  route_table_id = module.common_local_route_rt.route_table_id
}

# Associate Database subnets with DBRouteTable
resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidrs)

  subnet_id      = module.database_subnets[count.index].subnet_id
  route_table_id = module.db_route_table.route_table_id
}

# Associate Locker Database subnets with Database-RT
resource "aws_route_table_association" "locker_database" {
  count = length(var.locker_database_subnet_cidrs)

  subnet_id      = module.locker_database_subnets[count.index].subnet_id
  route_table_id = module.database_route_table.route_table_id
}

# Associate Locker Server subnets with LockerServerS3
resource "aws_route_table_association" "locker_server" {
  count = length(var.locker_server_subnet_cidrs)

  subnet_id      = module.locker_server_subnets[count.index].subnet_id
  route_table_id = module.locker_server_s3_rt.route_table_id
}

# Associate ElastiCache subnets with RedisRouteTable
resource "aws_route_table_association" "elasticache" {
  count = length(var.elasticache_subnet_cidrs)

  subnet_id      = module.elasticache_subnets[count.index].subnet_id
  route_table_id = module.redis_route_table.route_table_id
}

# Associate Data Stack subnets with CommonLocalS3
resource "aws_route_table_association" "data_stack" {
  count = length(var.data_stack_subnet_cidrs)

  subnet_id      = module.data_stack_subnets[count.index].subnet_id
  route_table_id = module.common_local_s3_rt.route_table_id
}

# Associate Incoming Envoy subnets with CommonLocalS3
resource "aws_route_table_association" "incoming_envoy" {
  count = length(var.incoming_envoy_subnet_cidrs)

  subnet_id      = module.incoming_envoy_subnets[count.index].subnet_id
  route_table_id = module.common_local_s3_rt.route_table_id
}

# Associate Outgoing Proxy subnets with ProxyPeeringNAT (per AZ)
resource "aws_route_table_association" "outgoing_proxy" {
  count = length(var.outgoing_proxy_subnet_cidrs)

  subnet_id      = module.outgoing_proxy_subnets[count.index].subnet_id
  route_table_id = count.index == 0 ? module.proxy_peering_nat_a_rt[0].route_table_id : (count.index == 1 ? module.proxy_peering_nat_b_rt[0].route_table_id : module.proxy_peering_nat_c_rt[0].route_table_id)
}

# Associate Utils subnets with CommonLocalS3
resource "aws_route_table_association" "utils" {
  count = length(var.utils_subnet_cidrs)

  subnet_id      = module.utils_subnets[count.index].subnet_id
  route_table_id = module.common_local_s3_rt.route_table_id
}