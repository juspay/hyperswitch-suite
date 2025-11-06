resource "aws_vpc_endpoint" "main" {
  vpc_id            = var.vpc_id
  service_name      = var.service_name
  vpc_endpoint_type = var.vpc_endpoint_type

  # Gateway endpoint configuration
  route_table_ids = var.vpc_endpoint_type == "Gateway" ? var.route_table_ids : null

  # Interface/GatewayLoadBalancer endpoint configuration
  subnet_ids          = var.vpc_endpoint_type != "Gateway" ? var.subnet_ids : null
  security_group_ids  = var.vpc_endpoint_type == "Interface" ? var.security_group_ids : null
  private_dns_enabled = var.vpc_endpoint_type == "Interface" ? var.private_dns_enabled : null

  # DNS Configuration (only for Interface endpoints)
  dynamic "dns_options" {
    for_each = var.vpc_endpoint_type == "Interface" ? [1] : []
    content {
      dns_record_ip_type = var.dns_record_ip_type
    }
  }

  # IP Address Type (only for Interface endpoints)
  ip_address_type = var.vpc_endpoint_type == "Interface" ? var.ip_address_type : null

  # Policy
  policy = var.policy

  # Auto Accept
  auto_accept = var.auto_accept

  tags = merge(
    var.tags,
    {
      Name = var.endpoint_name
    }
  )

  timeouts {
    create = var.create_timeout
    update = var.update_timeout
    delete = var.delete_timeout
  }
}

# Security Group for Interface Endpoints
resource "aws_security_group" "endpoint" {
  count = var.create_security_group && var.vpc_endpoint_type == "Interface" ? 1 : 0

  name_prefix = "${var.endpoint_name}-"
  description = "Security group for VPC endpoint ${var.endpoint_name}"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.endpoint_name}-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Ingress rule - Allow HTTPS from VPC
resource "aws_security_group_rule" "endpoint_ingress_https" {
  count = var.create_security_group && var.vpc_endpoint_type == "Interface" ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr_block]
  security_group_id = aws_security_group.endpoint[0].id
  description       = "Allow HTTPS from VPC"
}

# Custom ingress rules
resource "aws_security_group_rule" "endpoint_ingress_custom" {
  for_each = var.create_security_group && var.vpc_endpoint_type == "Interface" ? var.custom_ingress_rules : {}

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = lookup(each.value, "cidr_blocks", null)
  security_group_id = aws_security_group.endpoint[0].id
  description       = lookup(each.value, "description", null)
}

# Egress rule - Allow all outbound
resource "aws_security_group_rule" "endpoint_egress" {
  count = var.create_security_group && var.vpc_endpoint_type == "Interface" ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.endpoint[0].id
  description       = "Allow all outbound traffic"
}
