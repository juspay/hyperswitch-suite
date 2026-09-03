include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../modules/composition/artifact-registry"
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
    hyperswitch-router = {
      description    = "Hyperswitch router application image (mirrors AWS ECR hyperswitch-router)"
      format         = "DOCKER"
      immutable_tags = false
      cleanup_policies = {
        keep-recent = {
          action               = "KEEP"
          most_recent_versions = 15
        }
      }
    }
    hyperswitch-consumer = {
      description    = "Hyperswitch consumer application image (mirrors AWS ECR hyperswitch-consumer)"
      format         = "DOCKER"
      immutable_tags = false
      cleanup_policies = {
        keep-recent = {
          action               = "KEEP"
          most_recent_versions = 15
        }
      }
    }
    hyperswitch-producer = {
      description    = "Hyperswitch producer application image (mirrors AWS ECR hyperswitch-producer)"
      format         = "DOCKER"
      immutable_tags = false
      cleanup_policies = {
        keep-recent = {
          action               = "KEEP"
          most_recent_versions = 15
        }
      }
    }
    hyperswitch-drainer = {
      description    = "Hyperswitch drainer application image (mirrors AWS ECR hyperswitch-drainer)"
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
