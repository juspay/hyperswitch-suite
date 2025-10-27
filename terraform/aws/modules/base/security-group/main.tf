resource "aws_security_group" "this" {
  name                   = var.name
  description            = var.description
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  # Explicitly set empty egress to remove default rule
  # Rules are managed by aws_vpc_security_group_egress_rule resources
  egress = []

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [egress]
  }
}

# Ingress rules
resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for idx, rule in var.ingress_rules : idx => rule }

  security_group_id = aws_security_group.this.id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol

  # Conditionally set the source based on what's provided
  cidr_ipv4                    = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks[0] : null
  cidr_ipv6                    = length(each.value.ipv6_cidr_blocks) > 0 ? each.value.ipv6_cidr_blocks[0] : null
  referenced_security_group_id = each.value.source_security_group_id
  # Note: 'self' is handled by referencing this security group's ID
}

# Egress rules
resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = { for idx, rule in var.egress_rules : idx => rule }

  security_group_id = aws_security_group.this.id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol

  # Conditionally set the destination based on what's provided
  cidr_ipv4                    = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks[0] : null
  cidr_ipv6                    = length(each.value.ipv6_cidr_blocks) > 0 ? each.value.ipv6_cidr_blocks[0] : null
  referenced_security_group_id = each.value.source_security_group_id
}
