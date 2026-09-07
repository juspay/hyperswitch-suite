locals {
  environment = { full = "dev", short = "dev" }
  region      = "asia-south1"

  project_name = "hyperswitch"

  project_id     = "hyperswitch-dev"
  project_number = "000000000000"

  state_bucket_name = "hyperswitch-dev-asia-south1-terraform-state"

  vpn_cidr_blocks = [
    { cidr_block = "203.0.113.10/32", display_name = "vpn" },
    { cidr_block = "203.0.113.11/32", display_name = "vpn" },
    { cidr_block = "198.51.100.0/30", display_name = "office" },
    { cidr_block = "203.0.113.12/32", display_name = "vpn" },
    { cidr_block = "198.51.100.8/29", display_name = "office" },
    { cidr_block = "198.51.100.16/29", display_name = "office" },
    { cidr_block = "192.0.2.10/32", display_name = "phantom" },
    { cidr_block = "192.0.2.11/32", display_name = "phantom" },
    { cidr_block = "198.51.100.24/32", display_name = "office" },
    { cidr_block = "192.0.2.12/32", display_name = "phantom" },
    { cidr_block = "198.51.100.32/29", display_name = "office" },
    { cidr_block = "198.51.100.40/32", display_name = "office" },

    { cidr_block = "10.2.67.0/24", display_name = "management-subnet-bastion" },
  ]

  domains = ["dev.hyperswitch.internal"]

  bastion_iap_members = [
    "group:platform-team@example.com",
  ]

  gke_master_ipv4_cidr_block = "172.16.0.0/28"

  gke_node_pool_target_tags = ["gke-app-pool", "gke-system-pool"]

  machine_types = {
    gke_system_pool     = "e2-standard-2"
    gke_generic_compute = "e2-standard-2"
    bastion             = "e2-small"
  }
}

remote_state {
  backend = "gcs"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket   = local.state_bucket_name
    prefix   = "${local.environment.full}/${local.region}/${path_relative_to_include()}"
    project  = local.project_id
    location = local.region

    skip_bucket_creation = false
  }

  disable_init = false
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "google" {
  project = "${local.project_id}"
  region  = "${local.region}"
}

provider "google-beta" {
  project = "${local.project_id}"
  region  = "${local.region}"
}
EOF
}
