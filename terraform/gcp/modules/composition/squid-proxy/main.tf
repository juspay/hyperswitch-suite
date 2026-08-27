# ============================================================================
# Squid Egress Proxy (GCP equivalent of composition/squid-proxy)
# ============================================================================
# Autoscaled Squid fleet on Compute Engine (instance template + MIG) fronted
# by an internal TCP load balancer, with config/log GCS buckets - mirroring
# the AWS module's ASG + NLB + S3-config/log shape. Unlike the AWS module,
# this does not build its own NAT path: outbound internet access for
# clients routing through Squid is provided by the Cloud Router + Cloud NAT
# already created in composition/vpc-network.
#
# Usage:
#   module "squid_proxy" {
#     source = "../../modules/composition/squid-proxy"
#
#     project_id       = "hyperswitch-dev"
#     environment      = "dev"
#     region           = "europe-west1"
#     network          = module.vpc_network.network_self_link
#     proxy_subnetwork = module.vpc_network.subnets_by_tier["outgoing-proxy"]
#     lb_subnetwork    = module.vpc_network.subnets_by_tier["outgoing-proxy"]
#     squid_image      = "projects/hyperswitch-dev/global/images/squid-v1"
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

module "config_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "12.3.0"

  project_id         = var.project_id
  name               = "${local.name_prefix}-config"
  location           = var.bucket_location
  versioning         = true
  bucket_policy_only = true
  labels             = local.common_labels
}

module "log_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "12.3.0"

  project_id         = var.project_id
  name               = "${local.name_prefix}-logs"
  location           = var.bucket_location
  versioning         = true
  bucket_policy_only = true

  lifecycle_rules = [{
    action    = { type = "Delete" }
    condition = { age = var.log_retention_days }
  }]

  labels = local.common_labels
}

resource "google_storage_bucket_object" "squid_config" {
  count = var.squid_config_content != null ? 1 : 0

  bucket  = module.config_bucket.name
  name    = "squid.conf"
  content = var.squid_config_content
}

module "proxy_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "15.2.1"

  project_id   = var.project_id
  region       = var.region
  name_prefix  = local.name_prefix
  machine_type = var.machine_type

  source_image = var.squid_image
  disk_size_gb = var.disk_size_gb
  disk_type    = var.disk_type

  network    = var.network
  subnetwork = var.proxy_subnetwork

  service_account = {
    email  = module.service_account.email
    scopes = ["cloud-platform"]
  }

  tags     = ["squid-proxy"]
  labels   = local.common_labels
  metadata = merge(var.metadata, { "config-bucket" = module.config_bucket.name })
}

module "proxy_mig" {
  source  = "terraform-google-modules/vm/google//modules/mig"
  version = "15.2.1"

  project_id        = var.project_id
  region            = var.region
  mig_name          = local.name_prefix
  hostname          = local.name_prefix
  target_size       = var.min_replicas
  instance_template = module.proxy_template.self_link

  named_ports = [
    { name = "squid", port = var.squid_port },
  ]

  autoscaling_enabled = true
  min_replicas        = var.min_replicas
  max_replicas        = var.max_replicas
  autoscaling_cpu = [{
    target            = var.autoscaling_cpu_target
    predictive_method = "NONE"
  }]

  health_check = {
    type                = "tcp"
    initial_delay_sec   = 30
    check_interval_sec  = 10
    healthy_threshold   = 2
    timeout_sec         = 5
    unhealthy_threshold = 3
    response            = null
    proxy_header        = "NONE"
    port                = var.squid_port
    request             = null
    request_path        = null
    host                = null
    enable_logging      = true
  }

  labels = local.common_labels
}

module "internal_lb" {
  source  = "terraform-google-modules/lb-internal/google"
  version = "7.1.0"

  project    = var.project_id
  region     = var.region
  name       = "${local.name_prefix}-ilb"
  network    = var.network
  subnetwork = var.lb_subnetwork

  ports = [tostring(var.squid_port)]

  backends = [{ group = module.proxy_mig.instance_group }]

  source_tags = []
  target_tags = ["squid-proxy"]

  health_check = {
    type                = "tcp"
    port                = var.squid_port
    check_interval_sec  = 10
    timeout_sec         = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    proxy_header        = "NONE"
  }

  labels = local.common_labels
}
