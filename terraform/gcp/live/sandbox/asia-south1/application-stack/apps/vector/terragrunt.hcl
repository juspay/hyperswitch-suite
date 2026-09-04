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
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/application-resources/vector?ref=gcp-apps-vector-v0.1.0"
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

  bucket_location = include.root.locals.region

  # No cross-region reads configured yet (single-region setup).
  cross_region_reader_members = []

  k8s_namespace            = try(local.cfg.k8s_namespace, "vector")
  k8s_service_account_name = try(local.cfg.k8s_service_account_name, "vector-logging")
  use_existing_k8s_sa      = try(local.cfg.use_existing_k8s_sa, false)
  additional_project_roles = try(local.cfg.additional_project_roles, [])

  create_bucket          = try(local.cfg.create_bucket, true)
  bucket_name            = try(local.cfg.bucket_name, null)
  bucket_force_destroy   = try(local.cfg.bucket_force_destroy, false)
  bucket_lifecycle_rules = try(local.cfg.bucket_lifecycle_rules, [])

  create_queue                            = try(local.cfg.create_queue, true)
  subscription_ack_deadline_seconds       = try(local.cfg.subscription_ack_deadline_seconds, 60)
  subscription_message_retention_duration = try(local.cfg.subscription_message_retention_duration, "604800s")


  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
  }
}
