# ============================================================================
# Kafka (KRaft) on Compute Engine - GCP equivalent of composition/kafka
# ============================================================================
# Like its AWS counterpart, this module does not install Kafka itself: it
# provisions broker and controller Compute Engine instances from a
# pre-baked custom image (var.broker_image / var.controller_image) with
# static internal IPs, mirroring the AWS module's ENI-per-instance /
# fixed-identity design that KRaft's static voter-set config needs.
#
# Usage:
#   module "kafka" {
#     source = "../../modules/composition/kafka"
#
#     project_id       = "hyperswitch-dev"
#     environment      = "dev"
#     zone             = "europe-west1-b"
#     network          = module.vpc_network.network_self_link
#     subnetwork       = module.vpc_network.subnets_by_tier["data-stack"]
#     broker_image     = "projects/hyperswitch-dev/global/images/kafka-broker-v1"
#     controller_image = "projects/hyperswitch-dev/global/images/kafka-controller-v1"
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

resource "google_compute_address" "broker" {
  count = var.broker_count

  project      = var.project_id
  name         = "${local.name_prefix}-broker-${count.index}"
  region       = var.region
  subnetwork   = var.subnetwork
  address_type = "INTERNAL"
}

resource "google_compute_address" "controller" {
  count = var.controller_count

  project      = var.project_id
  name         = "${local.name_prefix}-controller-${count.index}"
  region       = var.region
  subnetwork   = var.subnetwork
  address_type = "INTERNAL"
}

module "broker_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "15.2.1"

  project_id   = var.project_id
  region       = var.region
  name_prefix  = "${local.name_prefix}-broker"
  machine_type = var.broker_machine_type

  source_image = var.broker_image
  disk_size_gb = var.broker_disk_size_gb
  disk_type    = var.disk_type

  network    = var.network
  subnetwork = var.subnetwork

  service_account = {
    email  = module.service_account.email
    scopes = ["cloud-platform"]
  }

  tags     = ["kafka-broker"]
  labels   = local.common_labels
  metadata = merge(var.metadata, { role = "broker" })
}

module "controller_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "15.2.1"

  project_id   = var.project_id
  region       = var.region
  name_prefix  = "${local.name_prefix}-controller"
  machine_type = var.controller_machine_type

  source_image = var.controller_image
  disk_size_gb = var.controller_disk_size_gb
  disk_type    = var.disk_type

  network    = var.network
  subnetwork = var.subnetwork

  service_account = {
    email  = module.service_account.email
    scopes = ["cloud-platform"]
  }

  tags     = ["kafka-controller"]
  labels   = local.common_labels
  metadata = merge(var.metadata, { role = "controller" })
}

module "broker_instances" {
  source  = "terraform-google-modules/vm/google//modules/compute_instance"
  version = "15.2.1"

  project_id        = var.project_id
  region            = var.region
  zone              = var.zone
  hostname          = "${local.name_prefix}-broker"
  num_instances     = var.broker_count
  instance_template = module.broker_template.self_link
  static_ips        = [for addr in google_compute_address.broker : addr.address]
  labels            = local.common_labels
}

module "controller_instances" {
  source  = "terraform-google-modules/vm/google//modules/compute_instance"
  version = "15.2.1"

  project_id        = var.project_id
  region            = var.region
  zone              = var.zone
  hostname          = "${local.name_prefix}-controller"
  num_instances     = var.controller_count
  instance_template = module.controller_template.self_link
  static_ips        = [for addr in google_compute_address.controller : addr.address]
  labels            = local.common_labels
}
