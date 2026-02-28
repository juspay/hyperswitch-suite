resource "aws_vpc" "main" {
  count = var.create ? 1 : 0

  cidr_block = var.vpc_cidr

  enable_dns_hostnames             = var.enable_dns_hostnames
  enable_dns_support               = var.enable_dns_support
  enable_network_address_usage_metrics = var.enable_network_address_usage_metrics

  instance_tenancy                 = var.instance_tenancy

  # Enable IPv6 if requested
  assign_generated_ipv6_cidr_block = var.enable_ipv6

  tags = merge(
    var.tags,
    {
      Name = var.vpc_name
    }
  )
}

# Secondary CIDR blocks for pod networking, expansion, etc.
resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  count = var.create ? length(var.secondary_cidr_blocks) : 0

  vpc_id     = aws_vpc.main[0].id
  cidr_block = var.secondary_cidr_blocks[count.index]
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  count = var.create && var.create_internet_gateway ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-igw"
    }
  )
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.create && var.enable_nat_gateway ? var.nat_gateway_count : 0

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# Default NACL - make it deny all by default for security
resource "aws_default_network_acl" "default" {
  count = var.create && var.manage_default_network_acl ? 1 : 0

  default_network_acl_id = aws_vpc.main[0].default_network_acl_id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-default-nacl"
    }
  )

  # No rules - deny all by default
  # Subnets should use custom NACLs
}

# Default security group - restrict by default
resource "aws_default_security_group" "default" {
  count = var.create && var.manage_default_security_group ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-default-sg"
    }
  )

  # No ingress/egress rules - deny all
  # Resources should use custom security groups
}

# Default route table
resource "aws_default_route_table" "default" {
  count = var.create && var.manage_default_route_table ? 1 : 0

  default_route_table_id = aws_vpc.main[0].default_route_table_id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-default-rt"
    }
  )

  # No routes - subnets should use custom route tables
}

# VPC Flow Logs for security monitoring
resource "aws_flow_log" "main" {
  count = var.create && var.enable_flow_logs ? 1 : 0

  iam_role_arn    = var.flow_logs_iam_role_arn
  log_destination = var.flow_logs_destination_arn
  traffic_type    = var.flow_logs_traffic_type
  vpc_id          = aws_vpc.main[0].id

  log_destination_type = var.flow_logs_destination_type
  log_format          = var.flow_logs_log_format

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-flow-logs"
    }
  )
}

# DHCP Options Set
resource "aws_vpc_dhcp_options" "main" {
  count = var.create_dhcp_options ? 1 : 0

  domain_name          = var.dhcp_options_domain_name
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = var.dhcp_options_ntp_servers
  netbios_name_servers = var.dhcp_options_netbios_name_servers
  netbios_node_type    = var.dhcp_options_netbios_node_type

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-dhcp-options"
    }
  )
}

resource "aws_vpc_dhcp_options_association" "main" {
  count = var.create_dhcp_options ? 1 : 0

  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.main[0].id
}
