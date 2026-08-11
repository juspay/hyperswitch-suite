# ============================================================================
# OpenSearch on Compute Engine - GCP equivalent of composition/opensearch
# ============================================================================
# GCP has no first-party managed OpenSearch/Elasticsearch service (unlike
# AWS's Amazon OpenSearch Service), so - consistent with kafka/cassandra/
# clickhouse - this module runs OpenSearch on a Compute Engine node fleet
# built from a pre-baked custom image, private-IP only, fronted by an
# internal TCP load balancer. See terraform/gcp/modules/README.md for the
# rationale and alternatives (Elastic Cloud on GCP Marketplace, BigQuery/Log
# Analytics) if a managed service is preferred instead.
#
# Usage:
#   module "opensearch" {
#     source = "../../modules/composition/opensearch"
#
#     project_id    = "hyperswitch-dev"
#     environment   = "dev"
#     region        = "europe-west1"
#     zone          = "europe-west1-b"
#     network       = module.vpc_network.network_self_link
#     subnetwork    = module.vpc_network.subnets_by_tier["data-stack"]
#     lb_subnetwork = module.vpc_network.subnets_by_tier["data-stack"]
#     node_image    = "projects/hyperswitch-dev/global/images/opensearch-v1"
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

resource "google_compute_disk" "data" {
  count = var.node_count

  project = var.project_id
  name    = "${local.name_prefix}-${count.index}-data"
  zone    = var.zone
  type    = var.disk_type
  size    = var.data_disk_size_gb
  labels  = local.common_labels
}

module "node_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "15.2.1"

  project_id   = var.project_id
  region       = var.region
  name_prefix  = local.name_prefix
  machine_type = var.machine_type

  source_image = var.node_image
  disk_size_gb = var.boot_disk_size_gb
  disk_type    = var.disk_type

  network    = var.network
  subnetwork = var.subnetwork

  service_account = {
    email  = module.service_account.email
    scopes = ["cloud-platform"]
  }

  tags     = ["opensearch-node"]
  labels   = local.common_labels
  metadata = var.metadata
}

module "node_group" {
  source  = "terraform-google-modules/vm/google//modules/umig"
  version = "15.2.1"

  project_id        = var.project_id
  region            = var.region
  zones             = [var.zone]
  hostname          = local.name_prefix
  num_instances     = var.node_count
  instance_template = module.node_template.self_link
  named_ports = [
    { name = "http", port = var.http_port },
  ]
}

resource "google_compute_attached_disk" "data" {
  count = var.node_count

  project     = var.project_id
  disk        = google_compute_disk.data[count.index].id
  instance    = module.node_group.instances_self_links[count.index]
  device_name = "opensearch-data"
}

module "internal_lb" {
  source  = "terraform-google-modules/lb-internal/google"
  version = "7.1.0"

  project    = var.project_id
  region     = var.region
  name       = "${local.name_prefix}-ilb"
  network    = var.network
  subnetwork = var.lb_subnetwork

  ports = [tostring(var.http_port)]

  backends = [
    for group in module.node_group.self_links : { group = group }
  ]

  source_tags = []
  target_tags = ["opensearch-node"]

  health_check = {
    type                = "http"
    port                = var.http_port
    check_interval_sec  = 10
    timeout_sec         = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    response            = null
    proxy_header        = "NONE"
  }

  labels = local.common_labels
}
