include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/application-resources/istio?ref=istio-v0.1.4"
}

dependency "eks" {
  config_path = "../../eks-01"

  mock_outputs = {
    cluster_name = "mock-cluster"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "vpc" {
  config_path = "../../../vpc-network"

  mock_outputs = {
    vpc_id = "vpc-mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {

  environment  = include.root.locals.environment.full
  region       = include.root.locals.region
  project_name = include.root.locals.project_name

  vpc_id = dependency.vpc.outputs.vpc_id

  eks_cluster_name = dependency.eks.outputs.cluster_name

  istio_namespace = "istio-system"

  create_helm_releases = false

  create_lb_security_group = true

  lb_security_groups = []

  host_domains = values.host_domains

  common_tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    Component   = "istio"
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }

}
