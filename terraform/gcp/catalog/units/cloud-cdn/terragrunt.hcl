# For static assets served from a GCS bucket (e.g. dashboard themes). No
# origin bucket configured by default - this is a template; point
# `backend_buckets` at a real bucket (e.g. from ../apps/hyperswitch's
# dashboard_themes_bucket_name output) before applying.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/cloud-cdn?ref=gcp-cloud-cdn-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  name_override = "assets"
  ssl           = false # no domain/certificate wired yet - see ../certificate-manager

  # TEMPLATE - no origin bucket configured. Fill in before applying:
  # backend_buckets = {
  #   assets = { bucket_name = "<gcs-bucket-name>" }
  # }
  backend_buckets = {}

  enable_logging = true

  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
  }
}
