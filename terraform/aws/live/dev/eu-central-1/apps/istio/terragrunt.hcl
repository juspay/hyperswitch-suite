include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../../modules/application-resources/istio"
}

dependency "vpc" {
  config_path = "../../vpc-network"

  mock_outputs = {
    vpc_id                       = "vpc-XXXXXXXXXXXXXXXXX"
    external_incoming_subnet_ids = ["subnet-XXXXXXXXXXXXXXXXX", "subnet-YYYYYYYYYYYYYYYYY", "subnet-ZZZZZZZZZZZZZZZZZ"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "eks" {
  config_path = "../../eks"

  mock_outputs = {
    cluster_name = "dev-hyperswitch-cluster-01"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  region       = include.root.locals.region
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  vpc_id        = dependency.vpc.outputs.vpc_id
  lb_subnet_ids = dependency.vpc.outputs.external_incoming_subnet_ids

  eks_cluster_name = dependency.eks.outputs.cluster_name

  create_lb_security_group = true
  lb_security_groups       = []

  istio_namespace = "istio-system"

  create_helm_releases = true

  istio_base = {
    enabled       = true
    release_name  = null
    chart_repo    = null
    chart_version = null
    values        = []
    values_file   = ""
  }

  istiod = {
    enabled       = true
    release_name  = null
    chart_repo    = null
    chart_version = null
    values        = []
    values_file   = ""
  }

  istio_gateway = {
    enabled       = true
    release_name  = null
    chart_repo    = null
    chart_version = null
    values        = []
    values_file   = ""
  }

  ingress_annotations = {}

  common_tags = {
    ManagedBy   = "terraform"
    Environment = "dev"
    Project     = "hyperswitch"
    Component   = "istio"
  }
}
