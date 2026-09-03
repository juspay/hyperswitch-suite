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
  source = "../../../..//modules/composition/cloud-dns"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  zone_name = "${include.root.locals.environment.short}-${include.root.locals.project_name}-internal"

  domain = "${include.root.locals.domains[0]}."

  type                               = "private"
  private_visibility_config_networks = [dependency.vpc.outputs.network_self_link]

  enable_dnssec = false

  recordsets = []

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "cloud-dns"
    managed_by  = "terraform"
  }
}
