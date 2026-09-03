include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../modules/composition/eks-kubernetes-resources"
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name                       = "dev-hyperswitch-cluster-01"
    cluster_id                         = "dev-hyperswitch-cluster-01"
    cluster_endpoint                   = "https://XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.gr7.eu-central-1.eks.amazonaws.com"
    cluster_certificate_authority_data = "XXXXXXXX"
    oidc_provider_arn                  = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  cluster_name                       = dependency.eks.outputs.cluster_name
  cluster_id                         = dependency.eks.outputs.cluster_id
  cluster_endpoint                   = dependency.eks.outputs.cluster_endpoint
  cluster_certificate_authority_data = dependency.eks.outputs.cluster_certificate_authority_data
  oidc_provider_arn                  = dependency.eks.outputs.oidc_provider_arn

  project_name = include.root.locals.project_name
  environment  = include.root.locals.environment.short
  region       = include.root.locals.region

  tags = {
    Project     = "hyperswitch"
    Environment = "dev"
    ManagedBy   = "terraform"
  }

  create_default_rbac_roles = true
  custom_rbac_roles         = {}

  create_default_storage_class = true
  default_storage_class_name   = "ebs-gp3"

  enable_cluster_autoscaler               = true
  cluster_autoscaler_image                = null
  cluster_autoscaler_service_account_name = null

  cluster_autoscaler_resources = {
    requests_cpu    = "100m"
    requests_memory = "600Mi"
    limits_cpu      = "100m"
    limits_memory   = "600Mi"
  }

  cluster_autoscaler_log_level          = 4
  cluster_autoscaler_expander           = "least-waste"
  cluster_autoscaler_extra_args         = []
  cluster_autoscaler_command            = null
  cluster_autoscaler_command_extra_args = []
  cluster_autoscaler_skip_local_storage = false
  cluster_autoscaler_skip_system_pods   = false
  cluster_autoscaler_node_selector      = {}
  cluster_autoscaler_tolerations        = []
  cluster_autoscaler_pod_annotations    = {}

  cluster_autoscaler_cluster_version = "1.35.0"
  cluster_autoscaler_image_version   = "v1.35.0"
  cluster_autoscaler_source_registry = "registry.k8s.io"
  cluster_autoscaler_architectures   = ["amd64", "arm64"]

  cluster_autoscaler_use_ecr            = true
  cluster_autoscaler_ecr_repo_name      = "dev-hyperswitch-cluster-autoscaler"
  cluster_autoscaler_ecr_max_images     = 5
  cluster_autoscaler_ecr_repository_url = "${include.root.locals.account_id}.dkr.ecr.${include.root.locals.region}.amazonaws.com/dev-hyperswitch-cluster-autoscaler"
  cluster_autoscaler_enable_image_sync  = true

  enable_helm_deployments    = false
  create_ecr_registry_secret = true

  hyperswitch_namespace       = "hyperswitch"
  hyperswitch_release_name    = "hyperswitch-stack"
  hyperswitch_helm_repository = "https://juspay.github.io/hyperswitch-helm"
  hyperswitch_helm_chart      = "hyperswitch-stack"
  hyperswitch_chart_version   = null
  hyperswitch_values_file     = null
  hyperswitch_helm_timeout    = 900
}
