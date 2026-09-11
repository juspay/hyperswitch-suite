# envoy_image needs a pre-baked custom image with Envoy installed - see
# values.custom_images in the stack.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_self_link = "projects/mock/global/networks/mock-vpc"
    subnets_by_tier   = { incoming-envoy = "projects/mock/regions/asia-south1/subnetworks/mock-incoming-envoy" }
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/envoy-proxy?ref=gcp-envoy-proxy-v0.1.0"
}

inputs = merge({
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  network          = dependency.vpc.outputs.network_self_link
  proxy_subnetwork = dependency.vpc.outputs.subnets_by_tier["incoming-envoy"]

  envoy_image = "projects/${include.root.locals.project_id}/global/images/${values.custom_images.envoy}"

  min_replicas = 2
  max_replicas = 6

  managed_ssl_certificate_domains = [values.domains.api]

  # ---------------------------------------------------------------------
  # Config pipeline
  # ---------------------------------------------------------------------
  # Without these two inputs the module uploads no envoy.yaml (the config
  # bucket object is count = 0 when envoy_config_content is null) and sets no
  # startup script, so the baked image boots with an empty /etc/envoy,
  # envoy.service crash-loops on "Invalid path: /etc/envoy/envoy.yaml", and
  # the GCLB backend sits UNHEALTHY. See templates/startup.sh for the full
  # explanation.
  #
  # get_terragrunt_dir() (not get_repo_root()): `terragrunt stack generate`
  # copies this unit's non-HCL files (config/, templates/) alongside the
  # generated terragrunt.hcl, so the paths below resolve correctly for any
  # consumer, not just a checkout of this repo.
  #
  # values.envoy is optional - the default here is a minimal single-cluster
  # passthrough (see config/envoy.yaml.tftpl).
  #
  # values.envoy.assets_dir swaps the BASE directory both paths below resolve
  # against, defaulting to this unit's own bundled config/ + templates/. Point
  # it at a private directory with the same config/envoy.yaml.tftpl and
  # templates/startup.sh layout to ship real Envoy config (extra filters,
  # auth, multiple clusters) without forking this unit or hand-rendering the
  # whole content yourself via values.cfg.
  envoy_config_content = try(values.envoy, null) != null ? templatefile("${try(values.envoy.assets_dir, get_terragrunt_dir())}/config/envoy.yaml.tftpl", {
    http_port     = 8080
    lb_ip         = try(values.envoy.lb_ip, "unknown")
    upstream_host = values.envoy.upstream_host
    upstream_port = try(values.envoy.upstream_port, 80)
  }) : null

  custom_startup_script = file("${try(values.envoy.assets_dir, get_terragrunt_dir())}/templates/startup.sh")

  enable_cloud_armor   = true
  enable_mtls_listener = false

  labels = merge({
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    managed_by  = "terraform"
  }, try(values.common_labels, {}))
}, try(values.cfg, {}))
