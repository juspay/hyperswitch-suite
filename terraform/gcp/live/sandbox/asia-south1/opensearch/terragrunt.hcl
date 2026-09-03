# node_image needs a pre-baked custom image with OpenSearch installed - see
# values.custom_images in the stack. See the module's own header comment for
# why this runs on Compute Engine instead of a managed service (GCP has
# none).

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_self_link = "projects/mock/global/networks/mock-vpc"
    subnets_by_tier   = { data-stack = "projects/mock/regions/asia-south1/subnetworks/mock-data-stack" }
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/opensearch?ref=gcp-opensearch-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region
  zone         = "${include.root.locals.region}-a"

  network       = dependency.vpc.outputs.network_self_link
  subnetwork    = dependency.vpc.outputs.subnets_by_tier["data-stack"]
  lb_subnetwork = dependency.vpc.outputs.subnets_by_tier["data-stack"]

  node_image = "projects/${include.root.locals.project_id}/global/images/${values.custom_images.opensearch}"

  node_count = 3

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    managed_by  = "terraform"
  }
}
