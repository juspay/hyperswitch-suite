include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../..//modules/application-resources/alb-controller"
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

  eks_cluster_name = dependency.eks.outputs.cluster_name

  alb_controller_namespace              = "kube-system"
  alb_controller_service_account_name   = "aws-load-balancer-controller-sa"
  create_alb_controller_service_account = true

  create_helm_release          = true
  alb_controller_chart_version = "1.14.0"
  helm_release_name            = "aws-load-balancer-controller"
  helm_chart_repository        = "https://aws.github.io/eks-charts"
  helm_chart_values            = []
  helm_values_file             = ""

  service_account_labels                 = {}
  additional_service_account_annotations = {}

  common_tags = {
    ManagedBy   = "terraform"
    Environment = "dev"
    Project     = "hyperswitch"
    Component   = "alb-controller"
  }
}
