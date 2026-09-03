# locker_image needs a pre-baked custom image with the card-vault software
# installed - see values.custom_images in the stack. Creates its own
# dedicated Cloud SQL database internally by default
# (create_locker_database = true) - no dependency on ../cloud-sql needed.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_self_link = "projects/mock/global/networks/mock-vpc"
    network_id        = "projects/mock/global/networks/mock-vpc"
    subnets_by_tier = {
      locker-server = "projects/mock/regions/asia-south1/subnetworks/mock-locker-server"
    }
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/locker?ref=gcp-locker-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region
  zone         = "${include.root.locals.region}-a"

  network       = dependency.vpc.outputs.network_self_link
  network_id    = dependency.vpc.outputs.network_id
  subnetwork    = dependency.vpc.outputs.subnets_by_tier["locker-server"]
  lb_subnetwork = dependency.vpc.outputs.subnets_by_tier["locker-server"]

  locker_image = "projects/${include.root.locals.project_id}/global/images/${values.custom_images.locker}"

  instance_count = 2

  create_locker_database = true
  database_config = {
    database_name   = "locker"
    master_username = "locker_admin"
  }

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    compliance  = "pci-dss"
    managed_by  = "terraform"
  }
}
