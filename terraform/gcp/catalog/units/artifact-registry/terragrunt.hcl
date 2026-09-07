# No dependency on vpc-network (Artifact Registry is a regional API service,
# not VPC-attached).

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/artifact-registry?ref=gcp-artifact-registry-v0.1.0"
}

inputs = {
  project_id  = include.root.locals.project_id
  environment = include.root.locals.environment.short
  location    = include.root.locals.region

  repositories = {
    hyperswitch = {
      description    = "Hyperswitch application images"
      format         = "DOCKER"
      immutable_tags = false
      cleanup_policies = {
        keep-recent = {
          action               = "KEEP"
          most_recent_versions = 15
        }
      }
    }
  }

  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
  }
}
