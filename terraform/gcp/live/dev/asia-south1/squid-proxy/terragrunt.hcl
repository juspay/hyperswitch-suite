include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_self_link = "projects/mock/global/networks/mock-vpc"
    subnets_by_tier   = { outgoing-proxy = "projects/mock/regions/asia-south1/subnetworks/mock-outgoing-proxy" }
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "../../../..//modules/composition/squid-proxy"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  network          = dependency.vpc.outputs.network_self_link
  proxy_subnetwork = dependency.vpc.outputs.subnets_by_tier["outgoing-proxy"]
  lb_subnetwork    = dependency.vpc.outputs.subnets_by_tier["outgoing-proxy"]

  squid_image = "projects/${include.root.locals.project_id}/global/images/family/hyperswitch-squid-dev"

  ilb_source_ranges = ["10.100.0.0/16", "10.2.32.0/20"]

  squid_config_content    = file("${get_terragrunt_dir()}/config/squid.conf")
  squid_allowlist_content = file("${get_terragrunt_dir()}/config/allowed-domains.txt")

  additional_config_files_path = "${get_terragrunt_dir()}/config"

  custom_startup_script = file("${get_terragrunt_dir()}/templates/startup-script.sh")

  min_replicas = 1
  max_replicas = 1

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    managed_by  = "terraform"
  }
}
