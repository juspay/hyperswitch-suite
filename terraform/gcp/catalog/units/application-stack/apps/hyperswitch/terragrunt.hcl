# The core application. KMS + GCS buckets created internally; SMTP left
# unwired by default (see decision-engine's unit for the same
# GCP-has-no-SES note).

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
  cfg = try(values.cfg, {})
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/application-resources/hyperswitch?ref=gcp-apps-hyperswitch-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  public_domain = values.domains.api

  cluster_name = dependency.gke.outputs.cluster_name

  # Required by the module since #310 — the Kubernetes/Helm provider is

  # configured from these rather than from a kubeconfig lookup.

  cluster_endpoint = dependency.gke.outputs.endpoint

  cluster_ca_certificate = dependency.gke.outputs.ca_certificate
  cluster_location       = dependency.gke.outputs.location

  kms = {
    create = true
    # Defaults to the region, but overridable per environment: an existing
    # keyring's location is baked into its resource ID and cannot be changed
    # in place, so pointing this at anything other than what is already live
    # would silently create a second, orphaned keyring rather than erroring.
    location        = try(local.cfg.kms_location, include.root.locals.region)
    rotation_period = "7776000s" # 90 days
  }

  gcs_dashboard_themes = {
    create             = true
    location           = include.root.locals.region
    versioning_enabled = true
  }

  gcs_file_uploads = {
    create             = true
    location           = include.root.locals.region
    versioning_enabled = true
  }

  smtp_secret_id = try(values.smtp_secret_id, null)

  secret_ids = []

  cloud_functions = {
    enabled = false
  }

  cross_project_assume = {
    enabled = false
  }

  additional_custom_role_ids = []

  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
    component   = "hyperswitch"
  }
}
