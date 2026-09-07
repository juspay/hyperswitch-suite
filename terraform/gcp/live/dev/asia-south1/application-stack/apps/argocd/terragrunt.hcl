include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "gke" {
  config_path = "../../gke"

  mock_outputs = {
    cluster_name   = "mock-cluster"
    location       = "asia-south1"
    endpoint       = "mock-endpoint"
    ca_certificate = "bW9jaw=="
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "../../../../../..//modules/application-resources/argocd"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  cluster_name     = dependency.gke.outputs.cluster_name
  cluster_location = dependency.gke.outputs.location

  cluster_endpoint       = dependency.gke.outputs.endpoint
  cluster_ca_certificate = dependency.gke.outputs.ca_certificate

  argocd_namespace = "argocd"

  argocd_service_accounts = [
    "argocd-application-controller",
    "argocd-applicationset-controller",
    "argocd-server",
  ]

  use_existing_k8s_sa = false

  additional_project_roles              = []
  cross_project_target_service_accounts = []

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "argocd"
    managed_by  = "terraform"
  }
}
