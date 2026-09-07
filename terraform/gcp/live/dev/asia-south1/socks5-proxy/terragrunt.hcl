# SOCKS5 egress proxy (Dante), for the application's SMTP path.
#
# hyperswitch's SMTP client dials its mail host through a SOCKS5 proxy when
# `email.smtp.socks5` is configured (juspay/hyperswitch#13984). Squid cannot
# serve that path - it is an HTTP forward proxy and speaks no SOCKS - so this
# is a second, protocol-distinct egress proxy rather than a change to
# ../squid-proxy.
#
# Set the application's email.smtp.socks5.host to this unit's
# internal_lb_ip_address output and .port to socks5_port.
#
# Needs a pre-baked image: terraform/gcp/packer/socks5-proxy.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_self_link = "projects/mock/global/networks/mock-vpc"
    subnets_by_tier   = { outgoing-proxy = "projects/mock/regions/mock-region/subnetworks/mock-outgoing-proxy" }
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

locals {
  cfg = try(values.cfg, {})
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/socks5-proxy?ref=gcp-socks5-proxy-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  # Same tier as squid: it is the subnet Cloud NAT covers, so the proxy can
  # actually reach the internet.
  network          = dependency.vpc.outputs.network_self_link
  proxy_subnetwork = dependency.vpc.outputs.subnets_by_tier["outgoing-proxy"]
  lb_subnetwork    = dependency.vpc.outputs.subnets_by_tier["outgoing-proxy"]

  socks5_image = "projects/${include.root.locals.project_id}/global/images/${values.custom_images.socks5}"

  socks5_port = try(local.cfg.socks5_port, 1080)

  # Same derivation as squid-proxy's ilb_source_ranges and the
  # gke-to-socks5-egress rule in ../firewall-rules: the gke-nodes subnet CIDR
  # and the pods secondary range. All three must agree.
  ilb_source_ranges = [
    "${values.vpc_cidr_prefix}.16.0/20",
    values.gke_pods_secondary_range_cidr,
  ]

  # Smaller than squid: this fleet carries SMTP only, not general egress.
  machine_type = try(local.cfg.machine_type, "e2-small")
  min_replicas = try(local.cfg.min_replicas, 2)
  max_replicas = try(local.cfg.max_replicas, 4)

  # Null leaves the image's boot-rendered no-auth default in place. Publish a
  # full danted.conf here to add RFC 1929 username/password auth - note it
  # travels in cleartext, so the network ACL above stays the real control.
  socks5_config_content = try(local.cfg.socks5_config_content, null)

  bucket_location = include.root.locals.region

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    managed_by  = "terraform"
  }
}
