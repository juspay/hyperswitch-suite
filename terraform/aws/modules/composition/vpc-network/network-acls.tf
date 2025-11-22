###################
# Network ACL - Single Simplified NACL for All Subnets
###################

# Single NACL applied to all subnets (matching integration environment)
module "main_nacl" {
  source = "../../base/network-acl"
  count  = var.create_nacl ? 1 : 0

  vpc_id     = module.vpc.vpc_id
  nacl_name  = "${var.vpc_name}-nacl"
  subnet_ids = concat(
    module.external_incoming_subnets[*].subnet_id,
    module.management_subnets[*].subnet_id,
    module.eks_workers_subnets[*].subnet_id,
    module.eks_control_plane_subnets[*].subnet_id,
    module.incoming_envoy_subnets[*].subnet_id,
    module.outgoing_proxy_subnets[*].subnet_id,
    module.utils_subnets[*].subnet_id,
    module.locker_server_subnets[*].subnet_id,
    module.data_stack_subnets[*].subnet_id,
    module.database_subnets[*].subnet_id,
    module.locker_database_subnets[*].subnet_id,
    module.elasticache_subnets[*].subnet_id
  )

  # Allow all inbound traffic
  ingress_rules = [
    {
      rule_number = 100
      protocol    = "-1"
      rule_action = "allow"
      cidr_block  = "0.0.0.0/0"
    }
  ]

  # Allow all outbound traffic
  egress_rules = [
    {
      rule_number = 100
      protocol    = "-1"
      rule_action = "allow"
      cidr_block  = "0.0.0.0/0"
    }
  ]

  tags = var.tags
}
