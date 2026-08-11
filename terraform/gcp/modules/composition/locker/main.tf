# ============================================================================
# Card Vault Locker (GCP equivalent of composition/locker)
# ============================================================================
# PCI-DSS scoped card-vault instances on Compute Engine, fronted by an
# internal TCP load balancer, with a dedicated CMEK key and (optionally) its
# own Cloud SQL database - mirroring the AWS module's EC2 + ALB + KMS +
# dedicated-RDS shape.
#
# Usage:
#   module "locker" {
#     source = "../../modules/composition/locker"
#
#     project_id    = "hyperswitch-dev"
#     environment   = "dev"
#     region        = "europe-west1"
#     zone          = "europe-west1-b"
#     network       = module.vpc_network.network_self_link
#     network_id    = module.vpc_network.network_id
#     subnetwork    = module.vpc_network.subnets_by_tier["locker-server"]
#     lb_subnetwork = module.vpc_network.subnets_by_tier["locker-server"]
#     locker_image  = "projects/hyperswitch-dev/global/images/locker-v1"
#
#     database_config = {
#       database_name   = "locker"
#       master_username = "locker_admin"
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
    "${var.project_id}=>roles/cloudkms.cryptoKeyEncrypterDecrypter",
  ]
}

module "locker_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "15.2.1"

  project_id   = var.project_id
  region       = var.region
  name_prefix  = local.name_prefix
  machine_type = var.machine_type

  source_image        = var.locker_image
  disk_size_gb        = var.disk_size_gb
  disk_type           = var.disk_type
  disk_encryption_key = module.kms.keys["locker"]

  network    = var.network
  subnetwork = var.subnetwork

  service_account = {
    email  = module.service_account.email
    scopes = ["cloud-platform"]
  }

  tags     = ["locker-node"]
  labels   = local.common_labels
  metadata = var.metadata
}

module "locker_group" {
  source  = "terraform-google-modules/vm/google//modules/umig"
  version = "15.2.1"

  project_id        = var.project_id
  region            = var.region
  zones             = [var.zone]
  hostname          = local.name_prefix
  num_instances     = var.instance_count
  instance_template = module.locker_template.self_link
  named_ports = [
    { name = "locker", port = var.locker_port },
  ]
}

module "internal_lb" {
  source  = "terraform-google-modules/lb-internal/google"
  version = "7.1.0"

  project    = var.project_id
  region     = var.region
  name       = "${local.name_prefix}-ilb"
  network    = var.network
  subnetwork = var.lb_subnetwork

  ports = [tostring(var.locker_port)]

  backends = [
    for group in module.locker_group.self_links : { group = group }
  ]

  source_tags = []
  target_tags = ["locker-node"]

  health_check = {
    type                = "http"
    port                = var.health_check_port
    request_path        = var.health_check_path
    check_interval_sec  = 10
    timeout_sec         = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    response            = null
    proxy_header        = "NONE"
  }

  labels = local.common_labels
}
