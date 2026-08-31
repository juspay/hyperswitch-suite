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

# force_destroy = true on both: these buckets' lifecycle is tied to this
# fleet's, and versioning = true means old object versions persist even
# after "deletion" - without force_destroy, `terraform destroy` fails
# outright ("Error trying to delete bucket ... without force_destroy set
# to true"), same failure mode confirmed live on ../envoy-proxy's
# equivalent buckets, 2026-08-20.
module "config_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "12.3.0"

  project_id         = var.project_id
  name               = "${local.name_prefix}-config"
  location           = var.bucket_location
  versioning         = true
  bucket_policy_only = true
  force_destroy      = true
  labels             = local.common_labels

  # Without this, the proxy service account can resolve the config-bucket
  # metadata key fine but squid-config-fetch.service's/the whitelist-cron
  # script's `gsutil cp` fails with a 403 (storage.objects.list denied) -
  # same real failure mode already confirmed on ../envoy-proxy's identical
  # setup, 2026-08-20. squid.service never gets a rendered config as a
  # result, since squid-config-fetch.service Before=squid.service but is
  # not itself Requires=d - it fails silently rather than blocking startup,
  # which is arguably worse (a stale/default squid.conf serving quietly
  # instead of a loud failure) - all the more reason this grant is not
  # optional.
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
  force_destroy      = true

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

# Whitelisted-domains file, synced periodically onto the instance by a cron
# job on the image (see ../../../packer/squid-proxy/scripts/
# update-squid-whitelist.sh) and applied via `squid -k reconfigure` - no
# instance replacement needed to roll out a whitelist change, matching the
# AWS AMI's userdata.sh cron (`*/15 * * * * root /etc/squid/
# update_whitelist.sh`, itself an `aws s3 cp` + `squid -k reconfigure`).
# Separate object/variable from squid_config_content so the two can change
# independently - a whitelist edit doesn't need to touch squid.conf, and
# vice versa.
resource "google_storage_bucket_object" "squid_allowlist" {
  count = var.squid_allowlist_content != null ? 1 : 0

  bucket  = module.config_bucket.name
  name    = "allowedlist.txt"
  content = var.squid_allowlist_content
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

  # iap-ssh matches the live VPC's already-existing, permanent
  # hyperswitch-dev-allow-iap-ssh rule (targetTags=[iap-ssh], source
  # 35.235.240.0/20) - same fix already applied to locker's and envoy's
  # modules after hitting the identical gap there.
  tags     = ["squid-proxy", "iap-ssh"]
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
  network    = local.internal_lb_network_name
  subnetwork = local.internal_lb_subnet_name

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
    # terraform-google-modules/lb-internal has no default for enable_log -
    # omitting it entirely coerces to null, and the module's own
    # google_compute_health_check resource does a null-incompatible
    # ternary on it ("Null condition" error). Same bug already found and
    # fixed in the locker composition module's identical internal_lb call
    # (see docs/superpowers/tracking/2026-08-19-gcp-dev-rollout-tracker.md,
    # Task L6, hyperswitch-infra repo).
    enable_log = false
  }

  labels = local.common_labels
}
