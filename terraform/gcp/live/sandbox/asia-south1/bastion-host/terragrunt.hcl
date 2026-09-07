# IAP-tunneled, no public IP.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_self_link = "projects/mock/global/networks/mock-vpc"
    subnets_by_tier   = { management = "projects/mock/regions/asia-south1/subnetworks/mock-management" }
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/bastion-host?ref=gcp-bastion-host-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region
  zone         = "${include.root.locals.region}-a"

  network = dependency.vpc.outputs.network_self_link
  subnet  = dependency.vpc.outputs.subnets_by_tier["management"]

  machine_type = values.machine_types.bastion

  # Workaround for a bug in terraform-google-modules/bastion-host v9.0.0:
  # its default image-family path (image=null, image_family="debian-12")
  # forwards a literal null through a nested `!= ""` sentinel check three
  # layers down (terraform-google-modules/vm's instance_template module),
  # which then tries to string-interpolate that null and fails at plan
  # time. Passing an explicit family self-link instead avoids the null
  # path entirely while still tracking the latest image in the family.
  image = "projects/debian-cloud/global/images/family/debian-12"

  members = values.bastion_iap_members

  enable_session_logging = true

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    managed_by  = "terraform"
  }
}
