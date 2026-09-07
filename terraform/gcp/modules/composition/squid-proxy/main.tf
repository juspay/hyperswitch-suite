# Squid egress proxy.
#
# Autoscaled Squid fleet on Compute Engine (instance template + MIG) fronted by
# an internal TCP load balancer, with config/log GCS buckets. This builds no NAT
# path of its own - outbound internet access comes from the Cloud Router +
# Cloud NAT in composition/vpc-network.

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

  # Required by squid-config-fetch.service and the whitelist cron job; without
  # it their fetches 403 and Squid serves a stale/default config silently,
  # since that unit is only Before= squid.service, not Requires=d by it.
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

resource "google_storage_bucket_object" "squid_config" {
  count = var.squid_config_content != null ? 1 : 0

  bucket  = module.config_bucket.name
  name    = "squid.conf"
  content = var.squid_config_content
}

# Optional override for the vector.toml baked into the image. Nothing in the
# image fetches this object on its own, so applying it needs a
# custom_startup_script.
resource "google_storage_bucket_object" "vector_config" {
  count = var.vector_config_content != null ? 1 : 0

  bucket  = module.config_bucket.name
  name    = "vector.toml"
  content = var.vector_config_content
}

# Whitelisted-domains file, synced onto the instance by a cron job on the image
# and applied via `squid -k reconfigure`, so a whitelist change rolls out
# without replacing instances. Kept separate from squid_config_content so the
# two can change independently.
resource "google_storage_bucket_object" "squid_allowlist" {
  count = var.squid_allowlist_content != null ? 1 : 0

  bucket  = module.config_bucket.name
  name    = "allowedlist.txt"
  content = var.squid_allowlist_content
}

# Generic multi-file config upload, alongside the three dedicated *_content
# variables above (kept for backward compatibility).
resource "google_storage_bucket_object" "additional_config_files" {
  for_each = var.additional_config_files_path != null ? setsubtract(
    fileset(var.additional_config_files_path, "**"),
    ["squid.conf", "allowedlist.txt", "vector.toml"]
  ) : toset([])

  bucket  = module.config_bucket.name
  name    = each.value
  content = file("${var.additional_config_files_path}/${each.value}")
}

module "proxy_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "15.2.1"

  project_id   = var.project_id
  region       = var.region
  name_prefix  = local.name_prefix
  machine_type = var.machine_type

  source_image         = local.squid_image_direct_name != null ? local.squid_image_direct_name : ""
  source_image_family  = local.squid_image_family_name != null ? local.squid_image_family_name : ""
  source_image_project = local.squid_image_project
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
  tags     = ["squid-proxy", "iap-ssh"]
  labels   = local.common_labels
  metadata = merge(var.metadata, { "config-bucket" = module.config_bucket.name })

  # Null by default: this fleet's config/whitelist delivery is handled by
  # systemd units baked into the image, not by a startup script.
  startup_script = var.custom_startup_script
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
  network    = local.internal_lb_network_name
  subnetwork = local.internal_lb_subnet_name

  ports = [tostring(var.squid_port)]

  backends = [{ group = module.proxy_mig.instance_group }]

  # var.ilb_source_ranges is what scopes the generated firewall rule: with
  # neither source_ip_ranges nor source_tags set, the API defaults sourceRanges
  # to 0.0.0.0/0. source_tags stays empty because Squid's clients are GKE pods,
  # which carry no network tags to match on.
  source_ip_ranges = var.ilb_source_ranges
  source_tags      = []
  target_tags      = ["squid-proxy"]

  health_check = {
    type                = "tcp"
    port                = var.squid_port
    check_interval_sec  = 10
    timeout_sec         = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    proxy_header        = "NONE"
    # lb-internal has no default for enable_log; omitting it coerces to null
    # and its health check does a null-incompatible ternary on the value.
    enable_log = false
  }

  labels = local.common_labels
}
