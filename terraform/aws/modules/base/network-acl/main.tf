resource "aws_network_acl" "main" {
  count = var.create ? 1 : 0

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = var.nacl_name
    }
  )
}

# Ingress Rules
resource "aws_network_acl_rule" "ingress" {
  for_each = var.create ? { for idx, rule in var.ingress_rules : idx => rule } : {}

  network_acl_id = aws_network_acl.main[0].id
  rule_number    = each.value.rule_number
  egress         = false
  protocol       = each.value.protocol
  rule_action    = each.value.rule_action
  cidr_block     = lookup(each.value, "cidr_block", null)
  ipv6_cidr_block = lookup(each.value, "ipv6_cidr_block", null)
  from_port      = lookup(each.value, "from_port", null)
  to_port        = lookup(each.value, "to_port", null)
  icmp_type      = lookup(each.value, "icmp_type", null)
  icmp_code      = lookup(each.value, "icmp_code", null)
}

# Egress Rules
resource "aws_network_acl_rule" "egress" {
  for_each = var.create ? { for idx, rule in var.egress_rules : idx => rule } : {}

  network_acl_id = aws_network_acl.main[0].id
  rule_number    = each.value.rule_number
  egress         = true
  protocol       = each.value.protocol
  rule_action    = each.value.rule_action
  cidr_block     = lookup(each.value, "cidr_block", null)
  ipv6_cidr_block = lookup(each.value, "ipv6_cidr_block", null)
  from_port      = lookup(each.value, "from_port", null)
  to_port        = lookup(each.value, "to_port", null)
  icmp_type      = lookup(each.value, "icmp_type", null)
  icmp_code      = lookup(each.value, "icmp_code", null)
}
