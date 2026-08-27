# ============================================================================
# ClickHouse on Compute Engine - GCP equivalent of composition/clickhouse
# ============================================================================
# Server + keeper tiers on pre-baked custom images with static internal IPs
# and dedicated persistent-disk data volumes, plus an internal TCP load
# balancer in front of the server tier (replacing the AWS module's internal
# ALB). Keeper nodes are addressed directly by static IP (ClickHouse Keeper,
# like Cassandra, needs a fixed peer list) so they sit behind no load
# balancer, matching the AWS module.
#
# Usage:
#   module "clickhouse" {
#     source = "../../modules/composition/clickhouse"
#
#     project_id    = "hyperswitch-dev"
#     environment   = "dev"
#     region        = "europe-west1"
#     zone          = "europe-west1-b"
#     network       = module.vpc_network.network_self_link
#     subnetwork    = module.vpc_network.subnets_by_tier["data-stack"]
#     lb_subnetwork = module.vpc_network.subnets_by_tier["data-stack"]
#     server_image  = "projects/hyperswitch-dev/global/images/clickhouse-server-v1"
#     keeper_image  = "projects/hyperswitch-dev/global/images/clickhouse-keeper-v1"
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

# ==============================================================================
# Keeper tier (fixed IPs, no load balancer - direct peer addressing)
# ==============================================================================
resource "google_compute_address" "keeper" {
  count = var.keeper_count

  project      = var.project_id
  name         = "${local.name_prefix}-keeper-${count.index}"
  region       = var.region
  subnetwork   = var.subnetwork
  address_type = "INTERNAL"
}

resource "google_compute_disk" "keeper_data" {
  count = var.keeper_count

  project = var.project_id
  name    = "${local.name_prefix}-keeper-${count.index}-data"
  zone    = var.zone
  type    = var.disk_type
  size    = var.keeper_disk_size_gb
  labels  = local.common_labels
}

module "keeper_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "15.2.1"

  project_id   = var.project_id
  region       = var.region
  name_prefix  = "${local.name_prefix}-keeper"
  machine_type = var.keeper_machine_type

  source_image = var.keeper_image
  disk_size_gb = var.keeper_boot_disk_size_gb
  disk_type    = var.disk_type

  network    = var.network
  subnetwork = var.subnetwork

  service_account = {
    email  = module.service_account.email
    scopes = ["cloud-platform"]
  }

  tags     = ["clickhouse-keeper"]
  labels   = local.common_labels
  metadata = var.metadata
}

module "keeper_instances" {
  source  = "terraform-google-modules/vm/google//modules/compute_instance"
  version = "15.2.1"

  project_id        = var.project_id
  region            = var.region
  zone              = var.zone
  hostname          = "${local.name_prefix}-keeper"
  num_instances     = var.keeper_count
  instance_template = module.keeper_template.self_link
  static_ips        = [for addr in google_compute_address.keeper : addr.address]
  labels            = local.common_labels
}

resource "google_compute_attached_disk" "keeper_data" {
  count = var.keeper_count

  project     = var.project_id
  disk        = google_compute_disk.keeper_data[count.index].id
  instance    = module.keeper_instances.instances_self_links[count.index]
  device_name = "clickhouse-keeper-data"
}

# ==============================================================================
# Server tier (fronted by an internal TCP load balancer)
# ==============================================================================
resource "google_compute_disk" "server_data" {
  count = var.server_count

  project = var.project_id
  name    = "${local.name_prefix}-server-${count.index}-data"
  zone    = var.zone
  type    = var.disk_type
  size    = var.server_disk_size_gb
  labels  = local.common_labels
}

module "server_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "15.2.1"

  project_id   = var.project_id
  region       = var.region
  name_prefix  = "${local.name_prefix}-server"
  machine_type = var.server_machine_type

  source_image = var.server_image
  disk_size_gb = var.server_boot_disk_size_gb
  disk_type    = var.disk_type

  network    = var.network
  subnetwork = var.subnetwork

  service_account = {
    email  = module.service_account.email
    scopes = ["cloud-platform"]
  }

  tags     = ["clickhouse-server"]
  labels   = local.common_labels
  metadata = var.metadata
}

module "server_group" {
  source  = "terraform-google-modules/vm/google//modules/umig"
  version = "15.2.1"

  project_id        = var.project_id
  region            = var.region
  zones             = [var.zone]
  hostname          = "${local.name_prefix}-server"
  num_instances     = var.server_count
  instance_template = module.server_template.self_link
  named_ports = [
    { name = "http", port = var.server_http_port },
    { name = "native", port = var.server_native_port },
  ]
}

resource "google_compute_attached_disk" "server_data" {
  count = var.server_count

  project     = var.project_id
  disk        = google_compute_disk.server_data[count.index].id
  instance    = module.server_group.instances_self_links[count.index]
  device_name = "clickhouse-server-data"
}

module "internal_lb" {
  source  = "terraform-google-modules/lb-internal/google"
  version = "7.1.0"

  project    = var.project_id
  region     = var.region
  name       = "${local.name_prefix}-server-ilb"
  network    = var.network
  subnetwork = var.lb_subnetwork

  ports = [tostring(var.server_native_port), tostring(var.server_http_port)]

  backends = [
    for group in module.server_group.self_links : { group = group }
  ]

  source_tags = []
  target_tags = ["clickhouse-server"]

  health_check = {
    type                = "http"
    port                = var.server_http_port
    check_interval_sec  = 10
    timeout_sec         = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    response            = null
    proxy_header        = "NONE"
  }

  labels = local.common_labels
}
