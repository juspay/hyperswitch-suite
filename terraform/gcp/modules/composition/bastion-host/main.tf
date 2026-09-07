# IAP-tunneled bastion with no public IP and no SSH key distribution. Session
# activity is captured via Cloud Logging; an optional GCS bucket + log sink give
# a durable audit trail.

module "bastion_host" {
  source  = "terraform-google-modules/bastion-host/google"
  version = "9.0.0"

  project = var.project_id
  region  = var.region
  zone    = var.zone

  network = var.network
  subnet  = var.subnet

  name         = local.instance_name
  machine_type = var.machine_type
  disk_size_gb = var.disk_size_gb
  disk_type    = var.disk_type

  image         = var.image
  image_family  = var.image == null ? var.image_family : null
  image_project = var.image_project

  members = var.members

  # Baseline roles first, live-layer additions appended (e.g.
  # roles/secretmanager.secretAccessor, to read the AlloyDB master password
  # from the box rather than copy-pasting it on).
  service_account_roles = concat(
    [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ],
    var.additional_service_account_roles,
  )

  labels = local.common_labels
  tags   = ["bastion-host", "iap-ssh"]

  shielded_vm = true
}

# Session logging
module "session_log_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "12.3.0"

  count = var.enable_session_logging ? 1 : 0

  project_id    = var.project_id
  name          = "${local.name_prefix}-session-logs"
  location      = var.log_bucket_location
  force_destroy = false

  versioning         = true
  bucket_policy_only = true

  lifecycle_rules = [{
    action    = { type = "Delete" }
    condition = { age = var.session_log_retention_days }
  }]

  labels = local.common_labels
}

resource "google_logging_project_sink" "session_logs" {
  count = var.enable_session_logging ? 1 : 0

  project     = var.project_id
  name        = "${local.name_prefix}-session-log-sink"
  destination = "storage.googleapis.com/${module.session_log_bucket[0].name}"

  filter = "resource.type=\"gce_instance\" AND resource.labels.instance_id=\"${module.bastion_host.self_link}\" AND logName:\"cloudaudit.googleapis.com\""

  unique_writer_identity = true
}

resource "google_storage_bucket_iam_member" "session_log_sink_writer" {
  count = var.enable_session_logging ? 1 : 0

  bucket = module.session_log_bucket[0].name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.session_logs[0].writer_identity
}
