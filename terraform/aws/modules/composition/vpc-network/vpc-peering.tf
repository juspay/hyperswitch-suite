locals {
  # Keep membership and keys independent of IDs, which are unknown when the
  # VPC/route tables are created or replaced. Only map values may be computed.
  public_route_tables = {
    common-internet    = module.common_internet_rt.route_table_id
    common-internet-s3 = module.common_internet_s3_rt.route_table_id
  }

  private_nat_route_tables = merge(
    var.enable_nat_gateway ? {
      common-local-nat-s3 = module.common_local_nat_s3_rt[0].route_table_id
    } : {},
    var.enable_nat_gateway && length(var.availability_zones) > 0 ? {
      proxy-peering-nat-a = module.proxy_peering_nat_a_rt[0].route_table_id
    } : {},
    var.enable_nat_gateway && length(var.availability_zones) > 1 ? {
      proxy-peering-nat-b = module.proxy_peering_nat_b_rt[0].route_table_id
    } : {},
    var.enable_nat_gateway && length(var.availability_zones) > 2 ? {
      proxy-peering-nat-c = module.proxy_peering_nat_c_rt[0].route_table_id
    } : {},
  )

  private_isolated_route_tables = {
    common-local    = module.common_local_route_rt.route_table_id
    common-local-s3 = module.common_local_s3_rt.route_table_id
  }

  database_route_tables = {
    db               = module.db_route_table.route_table_id
    redis            = module.redis_route_table.route_table_id
    database         = module.database_route_table.route_table_id
    locker-server-s3 = module.locker_server_s3_rt.route_table_id
  }

  eks_workers_route_tables = {
    eks-workers = module.eks_worker_rt.route_table_id
  }

  all_route_tables = merge(
    local.public_route_tables,
    local.private_nat_route_tables,
    local.private_isolated_route_tables,
    local.database_route_tables,
    local.eks_workers_route_tables,
  )

  route_table_groups = {
    all              = local.all_route_tables
    public           = local.public_route_tables
    private-nat      = local.private_nat_route_tables
    private-isolated = local.private_isolated_route_tables
    database         = local.database_route_tables
    eks-workers      = local.eks_workers_route_tables
  }

  # An explicit route-table ID remains supported as both key and value. These
  # IDs (and peer CIDRs) must be known at plan time; use groups for managed tables.
  requester_route_tables = {
    for peer_name, peer_config in var.vpc_peering_connections : peer_name => (
      contains(peer_config.route_tables, "all") ? local.all_route_tables : merge(
        {},
        [for rt in peer_config.route_tables : lookup(local.route_table_groups, rt, { (rt) = rt })]...
      )
    )
  }

  accepter_route_tables = {
    for peer_name, peer_config in var.vpc_peering_accepter_connections : peer_name => (
      contains(peer_config.route_tables, "all") ? local.all_route_tables : merge(
        {},
        [for rt in peer_config.route_tables : lookup(local.route_table_groups, rt, { (rt) = rt })]...
      )
    )
  }

  peering_route_expanded = var.enable_vpc_peering_routes ? flatten([
    for peer_name, peer_config in var.vpc_peering_connections : [
      for rt_name, rt_id in local.requester_route_tables[peer_name] : [
        for cidr in peer_config.peer_vpc_cidr : {
          key            = "${peer_name}-${rt_name}-${replace(cidr, "/", "-")}"
          peer_cidr      = cidr
          peering_id     = aws_vpc_peering_connection.requester[peer_name].id
          route_table_id = rt_id
        }
      ]
    ]
  ]) : []

  accepter_peering_route_expanded = var.enable_vpc_peering_routes ? flatten([
    for peer_name, peer_config in var.vpc_peering_accepter_connections : [
      for rt_name, rt_id in local.accepter_route_tables[peer_name] : [
        for cidr in peer_config.peer_vpc_cidr : {
          key            = "${peer_name}-${rt_name}-${replace(cidr, "/", "-")}"
          peer_cidr      = cidr
          peering_id     = peer_config.peering_connection_id
          route_table_id = rt_id
        }
      ]
    ]
  ]) : []
}

resource "aws_vpc_peering_connection" "requester" {
  for_each = var.vpc_peering_connections

  vpc_id        = module.vpc.vpc_id
  peer_vpc_id   = each.value.peer_vpc_id
  peer_region   = each.value.peer_region
  peer_owner_id = each.value.peer_owner_id

  auto_accept = each.value.auto_accept && each.value.peer_region == null && each.value.peer_owner_id == null

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = "${var.vpc_name}-peering-${each.key}"
      Side = "requester"
    }
  )
}

resource "aws_vpc_peering_connection_accepter" "accepter" {
  for_each = var.vpc_peering_accepter_connections

  vpc_peering_connection_id = each.value.peering_connection_id
  auto_accept               = true

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = "${var.vpc_name}-peering-accepter-${each.key}"
      Side = "accepter"
    }
  )
}

resource "aws_route" "peering_routes" {
  for_each = {
    for item in local.peering_route_expanded : item.key => item
  }

  route_table_id            = each.value.route_table_id
  destination_cidr_block    = each.value.peer_cidr
  vpc_peering_connection_id = each.value.peering_id
}

resource "aws_route" "accepter_peering_routes" {
  for_each = {
    for item in local.accepter_peering_route_expanded : item.key => item
  }

  route_table_id            = each.value.route_table_id
  destination_cidr_block    = each.value.peer_cidr
  vpc_peering_connection_id = each.value.peering_id
}
