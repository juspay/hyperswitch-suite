# SOCKS5 egress proxy (Dante).
#
# Autoscaled Dante fleet on Compute Engine (instance template + MIG) fronted by
# an internal TCP load balancer, with config/log GCS buckets. Structurally
# identical to composition/squid-proxy - the difference is the protocol: Squid
# speaks HTTP/HTTPS forward-proxy, this speaks SOCKS5, which is what the
# application's SMTP client dials (email.smtp.socks5 in the router config).
#
# This builds no NAT path of its own - outbound internet access comes from the
# Cloud Router + Cloud NAT in composition/vpc-network, so the proxy must sit in
# a subnet tier that NAT covers.

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

  # Required by socks5-config-fetch.service; without it the fetch 403s and the
  # instance silently falls back to the image's baked-in default config.
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

resource "google_storage_bucket_object" "socks5_config" {
  count = var.socks5_config_content != null ? 1 : 0

  bucket  = module.config_bucket.name
  name    = "danted.conf"
  content = var.socks5_config_content
}

resource "google_storage_bucket_object" "vector_config" {
  count = var.vector_config_content != null ? 1 : 0

  bucket  = module.config_bucket.name
  name    = "vector.toml"
  content = var.vector_config_content
}

resource "google_storage_bucket_object" "additional_config_files" {
  for_each = var.additional_config_files_path != null ? setsubtract(
    fileset(var.additional_config_files_path, "**"),
    ["danted.conf", "vector.toml"]
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

  source_image         = local.socks5_image_direct_name != null ? local.socks5_image_direct_name : ""
  source_image_family  = local.socks5_image_family_name != null ? local.socks5_image_family_name : ""
  source_image_project = local.socks5_image_project
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
  tags   = ["socks5-proxy", "iap-ssh"]
  labels = local.common_labels
  # socks5-port is read by the image's fetch-socks5-config.sh when it renders
  # the default config, so the listener and the LB/health-check agree without
  # rebuilding the image.
  metadata = merge(var.metadata, {
    "config-bucket" = module.config_bucket.name
    "socks5-port"   = tostring(var.socks5_port)
  })

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
    { name = "socks5", port = var.socks5_port },
  ]

  autoscaling_enabled = true
  min_replicas        = var.min_replicas
  max_replicas        = var.max_replicas
  autoscaling_cpu = [{
    target            = var.autoscaling_cpu_target
    predictive_method = "NONE"
  }]

  # TCP health check on the SOCKS port. Dante accepts the TCP connection before
  # any SOCKS handshake, so a plain connect is a valid liveness signal - the
  # same shape squid-proxy uses on 3128.
  health_check = {
    type                = "tcp"
    initial_delay_sec   = 30
    check_interval_sec  = 10
    healthy_threshold   = 2
    timeout_sec         = 5
    unhealthy_threshold = 3
    response            = null
    proxy_header        = "NONE"
    port                = var.socks5_port
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

  ports = [tostring(var.socks5_port)]

  backends = [{ group = module.proxy_mig.instance_group }]

  # var.ilb_source_ranges is what scopes the generated firewall rule: with
  # neither source_ip_ranges nor source_tags set, the API defaults sourceRanges
  # to 0.0.0.0/0. source_tags stays empty because the clients are GKE pods,
  # which carry no network tags to match on.
  source_ip_ranges = var.ilb_source_ranges
  source_tags      = []
  target_tags      = ["socks5-proxy"]

  health_check = {
    type                = "tcp"
    port                = var.socks5_port
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
