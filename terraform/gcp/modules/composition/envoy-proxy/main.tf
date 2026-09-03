# Envoy ingress proxy fleet.
#
# A self-managed, autoscaled Envoy fleet on Compute Engine (instance template +
# MIG) fronted by a global external HTTP(S) load balancer, with Cloud Armor for
# WAF, Secret Manager for the Envoy config, and GCS buckets for config/log
# archival.
#
# mTLS is served by a separate regional external proxy with its own Server TLS
# Policy: Cloud Load Balancing cannot mix TLS modes across listeners on a single
# LB the way an ALB can.

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

# Config / log buckets.
#
# force_destroy is env-gated (true except in prod): with versioning on,
# `terraform destroy` fails on the noncurrent object versions left behind.
module "config_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "12.3.0"

  project_id         = var.project_id
  name               = "${local.name_prefix}-config"
  location           = var.bucket_location
  versioning         = true
  bucket_policy_only = true
  force_destroy      = local.force_destroy_buckets
  labels             = local.common_labels

  # envoy-config-fetch.service needs this to read the bucket; without it the
  # fetch 403s and envoy.service (which Requires= it) never starts.
  iam_members = [{
    role   = "roles/storage.objectViewer"
    member = "serviceAccount:${module.service_account.email}"
  }]
}

module "log_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "12.3.0"

  project_id         = var.project_id
  name               = "${local.name_prefix}-logs"
  location           = var.bucket_location
  versioning         = true
  bucket_policy_only = true
  force_destroy      = local.force_destroy_buckets

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

# Generic multi-file config upload, alongside the single-file
# envoy_config_content (kept for backward compatibility).
resource "google_storage_bucket_object" "additional_config_files" {
  for_each = var.additional_config_files_path != null ? setsubtract(
    fileset(var.additional_config_files_path, "**"), ["envoy.yaml"]
  ) : toset([])

  bucket  = module.config_bucket.name
  name    = each.value
  content = file("${var.additional_config_files_path}/${each.value}")
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

# Proxy fleet
module "proxy_template" {
  source   = "terraform-google-modules/vm/google//modules/instance_template"
  version  = "15.2.1"
  for_each = local.resolved_deployments

  project_id   = var.project_id
  region       = var.region
  name_prefix  = "${local.name_prefix}-${each.key}"
  machine_type = each.value.machine_type

  source_image         = local.deployment_images[each.key].name
  source_image_project = local.deployment_images[each.key].project
  disk_size_gb         = var.disk_size_gb
  disk_type            = var.disk_type

  network    = var.network
  subnetwork = var.proxy_subnetwork

  service_account = {
    email  = module.service_account.email
    scopes = ["cloud-platform"]
  }

  # iap-ssh matches the VPC's tag-scoped IAP-SSH firewall rule; without it no
  # existing rule covers these instances.
  tags           = ["envoy-proxy", "iap-ssh"]
  labels         = merge(local.common_labels, { "deployment" = each.key })
  metadata       = merge(var.metadata, { "config-bucket" = module.config_bucket.name })
  startup_script = var.custom_startup_script
}

module "proxy_mig" {
  source   = "terraform-google-modules/vm/google//modules/mig"
  version  = "15.2.1"
  for_each = local.resolved_deployments

  project_id        = var.project_id
  region            = var.region
  mig_name          = "${local.name_prefix}-${each.key}"
  hostname          = "${local.name_prefix}-${each.key}"
  target_size       = each.value.min_replicas
  instance_template = module.proxy_template[each.key].self_link

  named_ports = [
    { name = "http", port = var.http_port },
    { name = "https", port = var.https_port },
    { name = "mtls", port = var.mtls_port },
  ]

  autoscaling_enabled = var.scaling_policies.cpu_target_tracking.enabled || var.scaling_policies.memory_target_tracking.enabled
  min_replicas        = each.value.min_replicas
  max_replicas        = each.value.max_replicas

  autoscaling_cpu = var.scaling_policies.cpu_target_tracking.enabled ? [{
    target            = var.scaling_policies.cpu_target_tracking.target_value
    predictive_method = "NONE"
  }] : []

  autoscaling_metric = var.scaling_policies.memory_target_tracking.enabled ? [{
    name   = "agent.googleapis.com/memory/percent_used"
    target = var.scaling_policies.memory_target_tracking.target_value
    type   = "GAUGE"
  }] : []

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

  labels = merge(local.common_labels, { "deployment" = each.key })
}

# Cloud Armor (WAF)
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

# HTTP(S) load balancer (external, global)
module "load_balancer" {
  source  = "GoogleCloudPlatform/lb-http/google"
  version = "14.2.0"

  project = var.project_id
  name    = "${local.name_prefix}-lb"

  firewall_networks = [var.network]

  ssl                             = true
  managed_ssl_certificate_domains = var.managed_ssl_certificate_domains
  https_redirect                  = var.enable_https_redirect

  # Required by google_compute_url_map.envoy's route_rules below: the classic
  # EXTERNAL scheme rejects advanced routing actions.
  load_balancing_scheme = "EXTERNAL_MANAGED"

  # This module's auto-generated url_map only ever sends 100% of traffic to a
  # single backend. google_compute_url_map.envoy replaces it to implement
  # weighted blue/green & canary deployments and listener_rules.
  create_url_map = false
  url_map        = google_compute_url_map.envoy.self_link

  backends = {
    for name, d in local.resolved_deployments : name => {
      port                    = var.http_port
      protocol                = "HTTP"
      port_name               = "http"
      timeout_sec             = 30
      enable_cdn              = var.enable_cdn
      security_policy         = var.enable_cloud_armor ? module.cloud_armor[0].policy.id : null
      custom_request_headers  = null
      custom_response_headers = null
      compression_mode        = null

      # CACHE_ALL_STATIC, not FORCE_CACHE_ALL: this backend also carries
      # non-cacheable payment API traffic, whose Cache-Control must be honored.
      cdn_policy = var.enable_cdn ? {
        cache_mode        = "CACHE_ALL_STATIC"
        client_ttl        = 3600
        default_ttl       = 3600
        max_ttl           = 86400
        negative_caching  = false
        serve_while_stale = 86400
        # Exactly one of cache_key_policy / signed_url_cache_max_age_sec must
        # be set explicitly; this varies the cache by full URL.
        cache_key_policy = {
          include_host         = true
          include_protocol     = true
          include_query_string = true
        }
      } : null

      health_check = {
        request_path = var.health_check_path
        port         = var.http_port
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [{
        group = module.proxy_mig[name].instance_group
      }]

      iap_config = null
    }
  }

  labels = local.common_labels
}

# A `check` block rather than a variable `validation`: cross-variable
# references in validations need Terraform >= 1.9, this module targets >= 1.5.
check "listener_rules_target_deployment_valid" {
  assert {
    condition = alltrue([
      for r in var.listener_rules :
      r.action.type != "forward" || contains(keys(var.deployments), coalesce(r.action.target_deployment, ""))
    ])
    error_message = "Each listener_rules[*] with action.type = \"forward\" must set action.target_deployment to a key present in var.deployments."
  }
}

# URL map: weighted traffic split across deployments (blue/green & canary),
# plus host/path/header listener_rules evaluated ahead of the weighted default.
resource "google_compute_url_map" "envoy" {
  project = var.project_id
  name    = "${local.name_prefix}-url-map"

  # Required by the schema as a fallback for requests matching no host_rule.
  # Unreachable in practice - the "default" path_matcher matches hosts = ["*"].
  default_route_action {
    dynamic "weighted_backend_services" {
      for_each = local.resolved_deployments
      content {
        backend_service = nonsensitive(module.load_balancer.backend_services[weighted_backend_services.key].self_link)
        weight          = weighted_backend_services.value.weight
      }
    }
  }

  dynamic "host_rule" {
    for_each = local.path_matchers
    content {
      hosts        = host_rule.value.hosts
      path_matcher = host_rule.key
    }
  }

  dynamic "path_matcher" {
    for_each = local.path_matchers
    content {
      name = path_matcher.key

      default_route_action {
        dynamic "weighted_backend_services" {
          for_each = local.resolved_deployments
          content {
            backend_service = nonsensitive(module.load_balancer.backend_services[weighted_backend_services.key].self_link)
            weight          = weighted_backend_services.value.weight
          }
        }
      }

      dynamic "route_rules" {
        for_each = { for r in path_matcher.value.rules : r.priority => r }
        content {
          priority = route_rules.value.priority

          match_rules {
            prefix_match    = route_rules.value.path_exact == null ? coalesce(route_rules.value.path_prefix, "/") : null
            full_path_match = route_rules.value.path_exact

            dynamic "header_matches" {
              for_each = route_rules.value.headers
              content {
                header_name = header_matches.value.name
                exact_match = length(header_matches.value.values) == 1 ? header_matches.value.values[0] : null
                regex_match = length(header_matches.value.values) > 1 ? join("|", header_matches.value.values) : null
              }
            }
          }

          dynamic "url_redirect" {
            for_each = route_rules.value.action.type == "redirect" ? [route_rules.value.action.redirect] : []
            content {
              host_redirect          = url_redirect.value.host
              path_redirect          = url_redirect.value.path
              https_redirect         = url_redirect.value.https
              redirect_response_code = url_redirect.value.response_code
              strip_query            = false
            }
          }

          dynamic "route_action" {
            for_each = route_rules.value.action.type == "forward" ? [route_rules.value.action.target_deployment] : []
            content {
              weighted_backend_services {
                backend_service = nonsensitive(module.load_balancer.backend_services[route_action.value].self_link)
                weight          = 1000
              }
            }
          }
        }
      }
    }
  }
}

# mTLS listener (separate regional external proxy)
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
