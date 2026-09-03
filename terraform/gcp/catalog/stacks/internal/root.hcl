# =============================================================================
# Internal GCP stack — root configuration
# =============================================================================
# Values-driven root for the internal sandbox / dev / pre-prod / prod GCP
# deployments. Every environment-specific setting comes from the stack
# `values` supplied by terraform/gcp/live/terragrunt.stack.hcl — nothing
# below is hardcoded to a particular project, bucket or network.
#
# The four locals exposed here are the entire contract between this root and
# the 34 catalog units:
#
#   include.root.locals.environment.short   (72 references)
#   include.root.locals.project_name        (51 references)
#   include.root.locals.project_id          (42 references)
#   include.root.locals.region              (30 references)
#   include.root.locals.vpn_cidr_blocks     (gke only)
#
# Adding a local here is cheap; renaming one is not.
# =============================================================================

locals {
  # values.env must be one of the keys below; anything else is a hard error
  # rather than silently collapsing into another environment's state prefix.
  env_map = {
    "sandbox"  = { full = "sandbox", short = "sbx" }
    "dev"      = { full = "dev", short = "dev" }
    "pre-prod" = { full = "pre-prod", short = "prep" }
    "prod"     = { full = "prod", short = "prd" }
  }

  environment = local.env_map[values.env]
  region      = values.region
  project_id  = values.project_id

  # Prefix for every resource name the units build. Defaults to the
  # shortened "hyps" because GCP service-account IDs cap at 30 characters
  # and several per-service names (e.g. "<env>-<project_name>-clickhouse-
  # node") overflow that with a longer prefix.
  #
  # Override via values.project_name ONLY when adopting this stack for an
  # environment whose resources were already applied under a different
  # prefix — changing it against a live environment renames or recreates
  # essentially every resource in it.
  project_name = try(values.project_name, "hyps")

  # Office / VPN CIDRs allowed to reach the GKE control plane, as a plain
  # list of CIDR strings. Left empty, the gke unit falls back to an
  # allow-all placeholder that is NOT safe to apply — see
  # units/gke/terragrunt.hcl.
  vpn_cidr_blocks = try(values.vpn_cidr_blocks, [])
}

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------
# One GCS bucket per environment, one prefix per unit. Unlike the AWS side
# (which requires the bucket to pre-exist), Terragrunt creates the GCS bucket
# itself on the first unit's `init` when skip_bucket_creation is false — so
# this stack needs no separate bootstrap step. Set
# values.skip_bucket_creation = true to point at a bucket managed elsewhere.
# -----------------------------------------------------------------------------
remote_state {
  backend = "gcs"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket   = values.state_bucket
    prefix   = "${local.environment.full}/${local.region}/${path_relative_to_include()}"
    project  = local.project_id
    location = local.region

    skip_bucket_creation = try(values.skip_bucket_creation, false)
  }

  disable_init = false
}

# -----------------------------------------------------------------------------
# Providers
# -----------------------------------------------------------------------------
# google-beta is required by several composition modules (GKE release
# channels, Cloud DNS response policies, Certificate Manager); both are
# generated for every unit so no unit has to declare its own.
# -----------------------------------------------------------------------------
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "google" {
  project = "${local.project_id}"
  region  = "${local.region}"
}

provider "google-beta" {
  project = "${local.project_id}"
  region  = "${local.region}"
}
EOF
}
