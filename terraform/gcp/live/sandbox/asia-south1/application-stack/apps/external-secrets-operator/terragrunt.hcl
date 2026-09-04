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
  # NOTE: the published tag abbreviates the module name to `eso`.
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/application-resources/external-secrets-operator?ref=gcp-apps-eso-v0.1.0"
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

  # Project-wide roles/secretmanager.secretAccessor by default; switch to
  # scope_to_project = false + explicit secret_ids for least privilege.
  scope_to_project = true

  k8s_namespace            = try(local.cfg.k8s_namespace, "external-secrets-operator")
  k8s_service_account_name = try(local.cfg.k8s_service_account_name, "external-secrets-sa")
  use_existing_k8s_sa      = try(local.cfg.use_existing_k8s_sa, false)

  # Empty + scope_to_project means the operator may read any secret in the
  # project; list secret IDs here to narrow it.
  secret_ids               = try(local.cfg.secret_ids, [])
  additional_project_roles = try(local.cfg.additional_project_roles, [])


  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
  }
}
