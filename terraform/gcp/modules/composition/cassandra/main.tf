# ============================================================================
# Cassandra on Compute Engine - GCP equivalent of composition/cassandra
# ============================================================================
# Provisions a Cassandra node fleet from a pre-baked custom image with
# static internal IPs (Cassandra's seed-list config needs fixed addresses,
# same as the AWS module's ENI approach), plus a seed-discovery HTTP
# function so new nodes can look up the current seed list at boot time.
#
# The AWS module's Lambda + API Gateway pair becomes a single Cloud Run
# function (2nd gen) with an HTTPS trigger - GCP does not need a separate
# API Gateway resource for a simple HTTP-triggered function.
#
# Usage:
#   module "cassandra" {
#     source = "../../modules/composition/cassandra"
#
#     project_id  = "hyperswitch-dev"
#     environment = "dev"
#     zone        = "europe-west1-b"
#     network     = module.vpc_network.network_self_link
#     subnetwork  = module.vpc_network.subnets_by_tier["data-stack"]
#     node_image  = "projects/hyperswitch-dev/global/images/cassandra-v1"
#
#     seed_discovery_source = {
#       bucket = module.function_source_bucket.name
#       object = "cassandra-seed-discovery.zip"
#     }
#   }
# ============================================================================

module "service_account" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "4.7.0"

  project_id = var.project_id
  names      = ["${local.name_prefix}-node"]
  project_roles = [
    "${var.project_id}=>roles/logging.logWriter",
    "${var.project_id}=>roles/monitoring.metricWriter",
  ]
}

resource "google_compute_address" "node" {
  count = var.node_count

  project      = var.project_id
  name         = "${local.name_prefix}-${count.index}"
  region       = var.region
  subnetwork   = var.subnetwork
  address_type = "INTERNAL"
}

module "node_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "15.2.1"

  project_id   = var.project_id
  region       = var.region
  name_prefix  = local.name_prefix
  machine_type = var.machine_type

  source_image = var.node_image
  disk_size_gb = var.disk_size_gb
  disk_type    = var.disk_type

  network    = var.network
  subnetwork = var.subnetwork

  service_account = {
    email  = module.service_account.email
    scopes = ["cloud-platform"]
  }

  tags     = ["cassandra-node"]
  labels   = local.common_labels
  metadata = var.metadata
}

module "node_instances" {
  source  = "terraform-google-modules/vm/google//modules/compute_instance"
  version = "15.2.1"

  project_id        = var.project_id
  region            = var.region
  zone              = var.zone
  hostname          = local.name_prefix
  num_instances     = var.node_count
  instance_template = module.node_template.self_link
  static_ips        = [for addr in google_compute_address.node : addr.address]
  labels            = local.common_labels
}

# ==============================================================================
# Seed Discovery Function (replaces AWS Lambda + API Gateway)
# ==============================================================================
module "seed_discovery" {
  source  = "GoogleCloudPlatform/cloud-functions/google"
  version = "0.9.0"

  count = var.enable_seed_discovery ? 1 : 0

  project_id        = var.project_id
  function_name     = "${local.name_prefix}-seed-discovery"
  function_location = var.region
  location          = var.region
  description       = "Returns the current Cassandra seed node IP list"
  runtime           = var.seed_discovery_runtime
  entrypoint        = var.seed_discovery_entrypoint

  storage_source = var.seed_discovery_source

  service_config = {
    max_instance_count = 5
    min_instance_count = 0
    available_memory   = "256M"
    available_cpu      = "1"
    timeout_seconds    = 30
    runtime_env_variables = {
      SEED_IPS = join(",", [for addr in google_compute_address.node : addr.address])
    }
  }

  members = {
    invokers = ["serviceAccount:${module.service_account.email}"]
  }

  labels = local.common_labels
}
