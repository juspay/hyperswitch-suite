resource "aws_subnet" "main" {
  count = var.create ? 1 : 0

  vpc_id            = var.vpc_id
  cidr_block        = var.cidr_block
  availability_zone = var.availability_zone

  # IPv6 Configuration
  ipv6_cidr_block                 = var.ipv6_cidr_block
  assign_ipv6_address_on_creation = var.assign_ipv6_address_on_creation

  # Public IP Configuration
  map_public_ip_on_launch = var.map_public_ip_on_launch

  # Outpost Configuration
  customer_owned_ipv4_pool           = var.customer_owned_ipv4_pool
  map_customer_owned_ip_on_launch    = var.map_customer_owned_ip_on_launch
  outpost_arn                        = var.outpost_arn

  # DNS Configuration
  enable_dns64                                   = var.enable_dns64
  enable_resource_name_dns_a_record_on_launch    = var.enable_resource_name_dns_a_record_on_launch
  enable_resource_name_dns_aaaa_record_on_launch = var.enable_resource_name_dns_aaaa_record_on_launch
  private_dns_hostname_type_on_launch            = var.private_dns_hostname_type_on_launch

  tags = merge(
    var.tags,
    {
      Name = var.subnet_name
      Tier = var.subnet_tier
      Type = var.subnet_type
    }
  )
}

# Route Table
resource "aws_route_table" "main" {
  count = var.create && var.create_route_table ? 1 : 0

  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.subnet_name}-rt"
      Tier = var.subnet_tier
    }
  )
}

# Route Table Association
resource "aws_route_table_association" "main" {
  count = var.create && var.create_route_table ? 1 : 0

  subnet_id      = aws_subnet.main[0].id
  route_table_id = aws_route_table.main[0].id
}

# Associate with existing route table if provided
resource "aws_route_table_association" "existing" {
  count = var.create && !var.create_route_table && var.route_table_id != "" ? 1 : 0

  subnet_id      = aws_subnet.main[0].id
  route_table_id = var.route_table_id
}

# Internet Gateway Route (for public subnets)
resource "aws_route" "internet_gateway" {
  count = var.create && var.create_route_table && var.create_internet_gateway_route ? 1 : 0

  route_table_id         = aws_route_table.main[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.internet_gateway_id
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  count = var.create && var.create_nat_gateway ? 1 : 0

  allocation_id = var.nat_gateway_eip_allocation_id
  subnet_id     = aws_subnet.main[0].id

  connectivity_type = var.nat_gateway_connectivity_type

  tags = merge(
    var.tags,
    {
      Name = "${var.subnet_name}-nat"
    }
  )

  depends_on = [var.internet_gateway_id]
}

# NAT Gateway Route (for private subnets with internet access)
resource "aws_route" "nat_gateway" {
  count = var.create_route_table && var.create_nat_gateway_route ? 1 : 0

  route_table_id         = aws_route_table.main[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_id
}
