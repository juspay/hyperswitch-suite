# Shared NFS storage, e.g. for workloads needing a ReadWriteMany volume.
# Not part of the critical path for a base Hyperswitch deployment - included
# because it's one of the modules we built. Disabled by default; flip
# `instances` to a real map to provision.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_self_link = "projects/mock/global/networks/mock-vpc"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/filestore?ref=gcp-filestore-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  # No shares provisioned by default - uncomment and size as needed.
  instances = {
    # shared = {
    #   zone    = "${include.root.locals.region}-a"
    #   network = dependency.vpc.outputs.network_self_link
    #   tier    = "BASIC_HDD"
    #   shares  = [{ name = "shared", capacity_gb = 1024 }]
    # }
  }

  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
  }
}
