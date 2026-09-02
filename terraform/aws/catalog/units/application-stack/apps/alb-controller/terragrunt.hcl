include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/application-resources/alb-controller?ref=alb-controller-v0.1.2"
}

dependency "eks" {
  config_path = "../../eks-01"

  mock_outputs = {
    cluster_name = "mock-cluster"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {

  environment  = include.root.locals.environment.full
  region       = include.root.locals.region
  project_name = include.root.locals.project_name

  eks_cluster_name = dependency.eks.outputs.cluster_name

  alb_controller_namespace = "kube-system"

  alb_controller_service_account_name = "aws-load-balancer-controller-sa"

  create_alb_controller_service_account = false

  service_account_labels = {}

  additional_service_account_annotations = {}

  create_helm_release = false

  common_tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    Component   = "alb-controller"
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }

}
