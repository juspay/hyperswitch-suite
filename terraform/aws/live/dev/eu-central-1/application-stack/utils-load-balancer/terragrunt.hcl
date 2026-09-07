include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/load-balancer?ref=load-balancer-v0.1.1"
}

dependency "vpc" {
  config_path = "../../vpc-network"

  mock_outputs = {
    external_incoming_subnet_ids = ["mock-external_incoming_subnet_ids"]
    vpc_id                       = "vpc-mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "eks" {
  config_path = "../eks-01"

  mock_outputs                           = {}
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  environment  = include.root.locals.environment.full
  region       = include.root.locals.region
  project_name = include.root.locals.project_name
  vpc_id       = dependency.vpc.outputs.vpc_id
  subnets      = dependency.vpc.outputs.external_incoming_subnet_ids

  create_alb = false

  ingress_rules = {}

  route53_zone = {
    create = false
  }

  route53_records = {}

  tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    Component   = "Application Stack Load Balancer"
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }
}
