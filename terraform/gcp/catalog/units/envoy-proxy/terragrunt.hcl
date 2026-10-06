# envoy_image needs a pre-baked custom image with Envoy installed - see
# values.custom_images in the stack.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_self_link  = "projects/mock/global/networks/mock-vpc"
    subnets_by_tier    = { incoming-envoy = "projects/mock/regions/asia-south1/subnetworks/mock-incoming-envoy" }
    gke_ingress_ilb_ip = "10.0.16.250"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
  # Restrict the mock to init/validate/plan only: without this, an existing
  # vpc-network state from before gke_ingress_ilb_ip existed would silently
  # merge the mock IP into apply too (shallow merge fills in any output
  # missing from real state with its mock value, with no warning). This
  # turns that into a loud error on apply instead of a wrong IP baked into
  # envoy.yaml - see upstream_host below.
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/envoy-proxy?ref=gcp-envoy-proxy-v0.1.1"
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
  # passthrough (see config/envoy.yaml).
  #
  # values.envoy.assets_dir swaps the BASE directory both paths below resolve
  # against, defaulting to this unit's own bundled config/ + templates/. Point
  # it at a private directory with the same config/envoy.yaml and
  # templates/startup.sh layout to ship real Envoy config (extra filters,
  # auth, multiple clusters) without forking this unit or hand-rendering the
  # whole content yourself via values.cfg.
  #
  # upstream_host: a stack can set values.envoy.upstream_host explicitly
  # (e.g. to point at something outside this VPC), but the normal case -
  # an in-cluster gateway's internal LoadBalancer IP (Istio's
  # ingressgateway) - now resolves automatically from vpc-network's
  # gke_ingress_ilb_ip output, with no value needed in the stack at all.
  # coalesce(), not try()'s own default: try() only catches evaluation
  # errors (a missing key), not an explicitly-set null, and the stack-level
  # key may be present-but-null in some callers.
  envoy_config_content = try(values.envoy, null) != null ? templatefile("${try(values.envoy.assets_dir, get_terragrunt_dir())}/config/envoy.yaml", {
    http_port     = 8080
    lb_ip         = try(values.envoy.lb_ip, "unknown")
    upstream_host = coalesce(try(values.envoy.upstream_host, null), dependency.vpc.outputs.gke_ingress_ilb_ip)
    upstream_port = try(values.envoy.upstream_port, 80)
  }) : null

  custom_startup_script = file("${try(values.envoy.assets_dir, get_terragrunt_dir())}/templates/startup.sh")

  # Every file under config/ becomes one object in the config bucket -
  # vector.toml uploads verbatim; envoy.yaml (matching envoy_config_filename's
  # default) gets envoy_config_content's already-rendered value instead of its
  # raw on-disk template text. One object per file, not two.
  #
  # The path must be ABSOLUTE, since Terraform resolves it from its own module
  # cache, not this directory - but abspath() on its own resolves a relative
  # path against the directory Terragrunt was launched from, not this unit's.
  # `terragrunt run --all` from a parent directory then pointed at a directory
  # that does not exist, so fileset() came back empty and the plan tried to
  # destroy the uploaded config objects. file()/templatefile() above resolve
  # relative to this unit, so assets_dir is a path relative to the unit (or
  # absolute); anchor a relative one to get_terragrunt_dir() so every caller
  # sees the same directory.
  config_files_source_path = abspath(try(
    substr(values.envoy.assets_dir, 0, 1) == "/"
    ? "${values.envoy.assets_dir}/config"
    : "${get_terragrunt_dir()}/${values.envoy.assets_dir}/config",
    "${get_terragrunt_dir()}/config",
  ))

  enable_cloud_armor   = true
  enable_mtls_listener = false

  labels = merge({
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    managed_by  = "terraform"
  }, try(values.common_labels, {}))
}, try(values.cfg, {}))
