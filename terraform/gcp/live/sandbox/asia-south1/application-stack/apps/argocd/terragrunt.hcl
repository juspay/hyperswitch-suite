include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "gke" {
  config_path = "../../gke"

  mock_outputs = {
    endpoint       = "mock-endpoint"
    ca_certificate = "bW9jaw=="
    cluster_name   = "mock-cluster"
    location       = "asia-south1"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

locals {
  # Per-environment overrides, passed by the stack as this unit's `cfg` value.
  # Defaults below are what the live dev environment runs.
  cfg = try(values.cfg, {})
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/application-resources/argocd?ref=gcp-apps-argocd-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  cluster_name = dependency.gke.outputs.cluster_name

  # Required by the module since #310 — the Kubernetes/Helm provider is

  # configured from these rather than from a kubeconfig lookup.

  cluster_endpoint = dependency.gke.outputs.endpoint

  cluster_ca_certificate = dependency.gke.outputs.ca_certificate
  cluster_location       = dependency.gke.outputs.location

  # No cross-project deployments configured yet.
  cross_project_target_service_accounts = []

  argocd_namespace = try(local.cfg.argocd_namespace, "argocd")
  argocd_service_accounts = try(local.cfg.argocd_service_accounts, [
    "argocd-application-controller",
    "argocd-applicationset-controller",
    "argocd-server",
  ])
  use_existing_k8s_sa      = try(local.cfg.use_existing_k8s_sa, false)
  additional_project_roles = try(local.cfg.additional_project_roles, [])


  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
  }
}
