resource "aws_route_table" "main" {
  count = var.create ? 1 : 0

  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = var.route_table_name
    }
  )
}

# Internet Gateway Route
resource "aws_route" "internet_gateway" {
  count = var.create && var.create_internet_gateway_route ? 1 : 0

  route_table_id         = aws_route_table.main[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.internet_gateway_id
}

# NAT Gateway Route
resource "aws_route" "nat_gateway" {
  count = var.create && var.create_nat_gateway_route ? 1 : 0

  route_table_id         = aws_route_table.main[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_id
}

# VPC Peering Route
resource "aws_route" "vpc_peering" {
  count = var.create && var.create_vpc_peering_route ? 1 : 0

  route_table_id            = aws_route_table.main[0].id
  destination_cidr_block    = var.vpc_peering_destination_cidr
  vpc_peering_connection_id = var.vpc_peering_connection_id
}
