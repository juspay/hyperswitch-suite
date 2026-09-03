# Must apply after ../gke - creates RBAC/storage-class resources against a
# live cluster (see the module's own header comment for why kubernetes/helm
# providers need a real endpoint to plan against).
#
# helm-managed Hyperswitch deployment is disabled by default here; ArgoCD
# (../apps/argocd) is the intended deployment path once it's wired up.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "gke" {
  config_path = "../gke"

  mock_outputs = {
    cluster_name   = "mock-cluster"
    endpoint       = "mock-endpoint"
    ca_certificate = "bW9jaw=="
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/gke-kubernetes-resources?ref=gcp-gke-kubernetes-resources-v0.1.0"
}

inputs = {
  cluster_name           = dependency.gke.outputs.cluster_name
  cluster_endpoint       = dependency.gke.outputs.endpoint
  cluster_ca_certificate = dependency.gke.outputs.ca_certificate

  project_name = include.root.locals.project_name
  environment  = include.root.locals.environment.short

  create_default_rbac_roles    = true
  create_default_storage_class = true

  enable_helm_deployments = false

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    managed_by  = "terraform"
  }
}
