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
  source = "../../../../modules/composition/envoy-proxy"
}

inputs = {
  project_id   = include.root.locals.project_id
  project_name = include.root.locals.project_name
  environment  = include.root.locals.environment.short
  region       = include.root.locals.region

  network          = dependency.vpc.outputs.network_self_link
  proxy_subnetwork = dependency.vpc.outputs.subnets_by_tier["management"]

  envoy_image = "projects/hyperswitch-dev/global/images/hyperswitch-envoy-dev-20260820032919"

  deployments = {
    stable = { weight = 100 }

  }

  listener_rules = []

  envoy_config_content = file("${get_terragrunt_dir()}/config/envoy.yaml")

  additional_config_files_path = "${get_terragrunt_dir()}/config"

  custom_startup_script = file("${get_terragrunt_dir()}/templates/startup-script.sh")

  machine_type = "e2-medium"
  min_replicas = 1
  max_replicas = 1

  enable_cloud_armor   = false
  enable_mtls_listener = false

  enable_cdn = true

  managed_ssl_certificate_domains = ["34-111-119-59.sslip.io"]

  enable_https_redirect = true

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "envoy-proxy"
    managed_by  = "terraform"
    purpose     = "smoke-test"
  }
}
