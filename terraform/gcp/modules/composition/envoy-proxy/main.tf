# ============================================================================
# Envoy Ingress Proxy Fleet (GCP equivalent of composition/envoy-proxy)
# ============================================================================
# A self-managed, autoscaled Envoy fleet on Compute Engine (instance
# template + MIG) fronted by a global external HTTP(S) load balancer, with
# Cloud Armor for WAF, Secret Manager for the Envoy config, and GCS buckets
# for config/log archival - mirroring the AWS module's ASG + ALB + WAF +
# S3-config/log shape.
#
# A separate regional external HTTPS listener with a Server TLS Policy
# provides the mTLS listener (mirrors PR #289's dedicated mTLS listener on
# the AWS side); Cloud Load Balancing has no single-LB-multi-listener-with-
# different-TLS-modes primitive the way an ALB does, so mTLS traffic is
# split onto its own regional proxy the same way the AWS module split it
# onto a separate ALB listener/target group.
#
# Usage:
#   module "envoy_proxy" {
#     source = "../../modules/composition/envoy-proxy"
#
#     project_id        = "hyperswitch-dev"
#     environment       = "dev"
#     region            = "europe-west1"
#     network           = module.vpc_network.network_self_link
#     proxy_subnetwork  = module.vpc_network.subnets_by_tier["incoming-envoy"]
#     envoy_image       = "projects/hyperswitch-dev/global/images/envoy-v1"
#
#     managed_ssl_certificate_domains = ["api.dev.hyperswitch.example.com"]
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
    "${var.project_id}=>roles/secretmanager.secretAccessor",
  ]
}

# ==============================================================================
# Config / log buckets
# ==============================================================================
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

resource "google_storage_bucket_object" "envoy_config" {
  count = var.envoy_config_content != null ? 1 : 0

  bucket  = module.config_bucket.name
  name    = "envoy.yaml"
  content = var.envoy_config_content
}

module "config_secret" {
  source  = "GoogleCloudPlatform/secret-manager/google"
  version = "0.9.0"

  count = var.envoy_config_content != null ? 1 : 0

  project_id = var.project_id
  secrets = [{
    name        = "${local.name_prefix}-config"
    secret_data = var.envoy_config_content
  }]
  secret_accessors_list = ["serviceAccount:${module.service_account.email}"]
}

# ==============================================================================
# Proxy fleet
# ==============================================================================
module "proxy_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "15.2.1"

  project_id   = var.project_id
  region       = var.region
  name_prefix  = local.name_prefix
  machine_type = var.machine_type

  source_image = var.envoy_image
  disk_size_gb = var.disk_size_gb
  disk_type    = var.disk_type

  network    = var.network
  subnetwork = var.proxy_subnetwork

  service_account = {
    email  = module.service_account.email
    scopes = ["cloud-platform"]
  }

  tags     = ["envoy-proxy"]
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
    { name = "http", port = var.http_port },
    { name = "https", port = var.https_port },
    { name = "mtls", port = var.mtls_port },
  ]

  autoscaling_enabled = true
  min_replicas        = var.min_replicas
  max_replicas        = var.max_replicas
  autoscaling_cpu = [{
    target            = var.autoscaling_cpu_target
    predictive_method = "NONE"
  }]

  health_check = {
    type                = "http"
    initial_delay_sec   = 30
    check_interval_sec  = 10
    healthy_threshold   = 2
    timeout_sec         = 5
    unhealthy_threshold = 3
    response            = null
    proxy_header        = "NONE"
    port                = var.http_port
    request             = null
    request_path        = var.health_check_path
    host                = null
    enable_logging      = true
  }

  labels = local.common_labels
}

# ==============================================================================
# Cloud Armor (WAF)
# ==============================================================================
module "cloud_armor" {
  source  = "GoogleCloudPlatform/cloud-armor/google"
  version = "8.1.1"

  count = var.enable_cloud_armor ? 1 : 0

  project_id          = var.project_id
  name                = "${local.name_prefix}-waf"
  default_rule_action = "allow"
  type                = "CLOUD_ARMOR"

  pre_configured_rules = var.cloud_armor_preconfigured_rules

  labels = local.common_labels
}

# ==============================================================================
# HTTP(S) Load Balancer (external, global)
# ==============================================================================
module "load_balancer" {
  source  = "GoogleCloudPlatform/lb-http/google"
  version = "14.2.0"

  project = var.project_id
  name    = "${local.name_prefix}-lb"

  firewall_networks = [var.network]

  ssl                             = true
  managed_ssl_certificate_domains = var.managed_ssl_certificate_domains
  https_redirect                  = true

  backends = {
    default = {
      port                    = var.http_port
      protocol                = "HTTP"
      port_name               = "http"
      timeout_sec             = 30
      enable_cdn              = false
      security_policy         = var.enable_cloud_armor ? module.cloud_armor[0].policy.id : null
      custom_request_headers  = null
      custom_response_headers = null
      compression_mode        = null

      health_check = {
        request_path = var.health_check_path
        port         = var.http_port
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [{
        group = module.proxy_mig.instance_group
      }]

      iap_config = null
    }
  }

  labels = local.common_labels
}

# ==============================================================================
# mTLS listener (separate regional external proxy, mirrors PR #289)
# ==============================================================================
resource "google_network_security_server_tls_policy" "mtls" {
  count = var.enable_mtls_listener ? 1 : 0

  project  = var.project_id
  name     = "${local.name_prefix}-mtls-policy"
  location = var.region

  mtls_policy {
    client_validation_mode         = "REJECT_INVALID"
    client_validation_trust_config = var.mtls_trust_config_id
  }
}
