###################
# VPC Endpoints
###################

locals {
  # Gateway endpoints (S3)
  gateway_endpoints = {
    s3 = {
      service_name = "com.amazonaws.${var.aws_region}.s3"
      type         = "Gateway"
    }
  }

  # Interface endpoints (common AWS services)
  interface_endpoints = {
    ec2 = {
      service_name = "com.amazonaws.${var.aws_region}.ec2"
      type         = "Interface"
    }
    ecr_api = {
      service_name = "com.amazonaws.${var.aws_region}.ecr.api"
      type         = "Interface"
    }
    ecr_dkr = {
      service_name = "com.amazonaws.${var.aws_region}.ecr.dkr"
      type         = "Interface"
    }
    ecs = {
      service_name = "com.amazonaws.${var.aws_region}.ecs"
      type         = "Interface"
    }
    ecs_telemetry = {
      service_name = "com.amazonaws.${var.aws_region}.ecs-telemetry"
      type         = "Interface"
    }
    ecs_agent = {
      service_name = "com.amazonaws.${var.aws_region}.ecs-agent"
      type         = "Interface"
    }
    elasticloadbalancing = {
      service_name = "com.amazonaws.${var.aws_region}.elasticloadbalancing"
      type         = "Interface"
    }
    logs = {
      service_name = "com.amazonaws.${var.aws_region}.logs"
      type         = "Interface"
    }
    monitoring = {
      service_name = "com.amazonaws.${var.aws_region}.monitoring"
      type         = "Interface"
    }
    secretsmanager = {
      service_name = "com.amazonaws.${var.aws_region}.secretsmanager"
      type         = "Interface"
    }
    ssm = {
      service_name = "com.amazonaws.${var.aws_region}.ssm"
      type         = "Interface"
    }
    ssmmessages = {
      service_name = "com.amazonaws.${var.aws_region}.ssmmessages"
      type         = "Interface"
    }
    ec2messages = {
      service_name = "com.amazonaws.${var.aws_region}.ec2messages"
      type         = "Interface"
    }
    kms = {
      service_name = "com.amazonaws.${var.aws_region}.kms"
      type         = "Interface"
    }
    lambda = {
      service_name = "com.amazonaws.${var.aws_region}.lambda"
      type         = "Interface"
    }
    sns = {
      service_name = "com.amazonaws.${var.aws_region}.sns"
      type         = "Interface"
    }
    sqs = {
      service_name = "com.amazonaws.${var.aws_region}.sqs"
      type         = "Interface"
    }
    rds = {
      service_name = "com.amazonaws.${var.aws_region}.rds"
      type         = "Interface"
    }
    athena = {
      service_name = "com.amazonaws.${var.aws_region}.athena"
      type         = "Interface"
    }
    kinesis_streams = {
      service_name = "com.amazonaws.${var.aws_region}.kinesis-streams"
      type         = "Interface"
    }
    kinesis_firehose = {
      service_name = "com.amazonaws.${var.aws_region}.kinesis-firehose"
      type         = "Interface"
    }
    glue = {
      service_name = "com.amazonaws.${var.aws_region}.glue"
      type         = "Interface"
    }
    states = {
      service_name = "com.amazonaws.${var.aws_region}.states"
      type         = "Interface"
    }
    events = {
      service_name = "com.amazonaws.${var.aws_region}.events"
      type         = "Interface"
    }
    sts = {
      service_name = "com.amazonaws.${var.aws_region}.sts"
      type         = "Interface"
    }
    autoscaling = {
      service_name = "com.amazonaws.${var.aws_region}.autoscaling"
      type         = "Interface"
    }
  }

  # Merge user-provided endpoints
  enabled_gateway_endpoints   = { for k, v in local.gateway_endpoints : k => v if contains(var.gateway_vpc_endpoints, k) }
  enabled_interface_endpoints = { for k, v in local.interface_endpoints : k => v if contains(var.interface_vpc_endpoints, k) }

  # Route table IDs for gateway endpoints (using shared route tables)
  gateway_route_table_ids = compact(concat(
    [module.common_internet_s3_rt.route_table_id],
    [module.common_local_s3_rt.route_table_id],
    [module.locker_server_s3_rt.route_table_id],
    # Per-AZ ProxyPeeringNAT route tables
    var.enable_nat_gateway && length(var.availability_zones) > 0 ? [module.proxy_peering_nat_a_rt[0].route_table_id] : [],
    var.enable_nat_gateway && length(var.availability_zones) > 1 ? [module.proxy_peering_nat_b_rt[0].route_table_id] : [],
    var.enable_nat_gateway && length(var.availability_zones) > 2 ? [module.proxy_peering_nat_c_rt[0].route_table_id] : [],
    # EKS Worker route table (NAT + S3)
    var.enable_nat_gateway ? [module.eks_worker_rt[0].route_table_id] : [],
    # Common Local NAT S3 route table (NAT + S3)
    var.enable_nat_gateway ? [module.common_local_nat_s3_rt[0].route_table_id] : [],
    var.include_database_route_tables_in_gateway_endpoints ? [module.db_route_table.route_table_id] : []
  ))
}

# Gateway VPC Endpoints (S3, DynamoDB)
module "gateway_vpc_endpoints" {
  source   = "../../base/vpc-endpoint"
  for_each = local.enabled_gateway_endpoints

  vpc_id           = module.vpc.vpc_id
  endpoint_name    = "${var.vpc_name}-${each.key}-endpoint"
  service_name     = each.value.service_name
  vpc_endpoint_type = each.value.type

  route_table_ids = local.gateway_route_table_ids

  tags = merge(
    var.tags,
    {
      Name    = "${var.vpc_name}-${each.key}-endpoint"
      Service = each.key
    }
  )
}

# Interface VPC Endpoints
module "interface_vpc_endpoints" {
  source   = "../../base/vpc-endpoint"
  for_each = local.enabled_interface_endpoints

  vpc_id            = module.vpc.vpc_id
  endpoint_name     = "${var.vpc_name}-${each.key}-endpoint"
  service_name      = each.value.service_name
  vpc_endpoint_type = each.value.type

  subnet_ids         = module.eks_workers_subnets[*].subnet_id
  security_group_ids = var.create_vpc_endpoint_security_group ? [module.vpc_endpoint_sg[0].sg_id] : var.vpc_endpoint_security_group_ids

  private_dns_enabled = var.vpc_endpoint_private_dns_enabled

  tags = merge(
    var.tags,
    {
      Name    = "${var.vpc_name}-${each.key}-endpoint"
      Service = each.key
    }
  )
}

# Security Group for VPC Endpoints
module "vpc_endpoint_sg" {
  source = "../../base/security-group"
  count  = var.create_vpc_endpoint_security_group ? 1 : 0

  name        = "${var.vpc_name}-vpc-endpoint-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description = "Allow HTTPS from VPC"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    }
  ]

  egress_rules = [
    {
      description = "Allow all outbound"
      from_port   = -1
      to_port     = -1
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-vpc-endpoint-sg"
    }
  )
}