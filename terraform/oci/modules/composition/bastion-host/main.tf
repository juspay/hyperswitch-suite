# The jump instance (bastion host access path)
resource "oci_core_instance" "this" {
  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  fault_domain        = var.fault_domain
  display_name        = local.display_name
  shape               = var.shape

  shape_config {
    ocpus         = var.shape_ocpus
    memory_in_gbs = var.shape_memory_in_gbs
  }

  # kms_key_id null = Oracle-managed boot-volume encryption.
  source_details {
    source_type             = "image"
    source_id               = var.image_id
    boot_volume_size_in_gbs = tostring(var.boot_volume_size_in_gbs)
    kms_key_id              = var.boot_volume_kms_key_id
  }

  create_vnic_details {
    subnet_id = var.subnet_id
    # assign_public_ip is a STRING on oci_core_instance - a real provider quirk.
    assign_public_ip = var.assign_public_ip ? "true" : "false"
    nsg_ids          = local.nsg_ids
    display_name     = "${local.display_name}-vnic"
    hostname_label   = replace(local.display_name, "-", "")
    freeform_tags    = local.freeform_tags
  }

  # cloud-init user-data delivered via instance metadata.
  metadata = local.instance_metadata

  instance_options {
    are_legacy_imds_endpoints_disabled = var.disable_legacy_imds_endpoints
  }

  agent_config {
    is_monitoring_disabled = false
    is_management_disabled = false

    # Oracle Bastion plugin enabled so Managed SSH isn't blocked by a reboot.
    dynamic "plugins_config" {
      for_each = var.enable_oracle_cloud_agent_bastion_plugin ? [1] : []

      content {
        name          = "Bastion"
        desired_state = "ENABLED"
      }
    }

    plugins_config {
      name          = "Compute Instance Monitoring"
      desired_state = "ENABLED"
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # The image is the boot artefact; instance holds no data, so nothing is ignored.
    ignore_changes = []
  }
}

# -----------------------------------------------------------------------------
# OCI Bastion service - session broker
# -----------------------------------------------------------------------------
# Security-relevant differences from the AWS/Ssm model:
#   - Every session requires an SSH keypair (key_details.public_key_content).
#   - Every session type needs one inbound rule on the target from the
#     bastion's private endpoint IP - see network.tf.
#   - No session-content logging exists; OCI Audit records control-plane calls only.
#   - No oci_bastion_session is created here, deliberately: sessions are
#     short-lived, per-operator objects, and managing one in Terraform would put
#     an operator's SSH public key in state. Operators create a PORT_FORWARDING
#     session via the connection-guide output.
resource "oci_bastion_bastion" "this" {
  count = var.create_bastion ? 1 : 0

  compartment_id   = var.compartment_id
  bastion_type     = "STANDARD"
  name             = replace("${local.display_name}", "-", "_")
  target_subnet_id = local.bastion_target_subnet_id

  # CIDR control over who may start a session.
  client_cidr_block_allow_list = var.bastion_client_cidr_allow_list

  # Session-LIFETIME cap (OCI has no idle-timer control).
  max_session_ttl_in_seconds = var.bastion_max_session_ttl_seconds

  # Lets a port-forwarding session target a hostname (data-tier private FQDN).
  dns_proxy_status = var.bastion_dns_proxy_status

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# -----------------------------------------------------------------------------
# Host log group and log
# -----------------------------------------------------------------------------
resource "oci_logging_log_group" "this" {
  compartment_id = var.compartment_id
  display_name   = replace("${local.display_name}-logs", "-", "_")
  description    = "Host-level logs for the ${local.display_name} jump host"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_logging_log" "host" {
  display_name       = replace("${local.display_name}-host", "-", "_")
  log_group_id       = oci_logging_log_group.this.id
  log_type           = "CUSTOM"
  is_enabled         = true
  retention_duration = var.log_retention_days

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# -----------------------------------------------------------------------------
# Self-managed session-recording archive
# -----------------------------------------------------------------------------
# A DESTINATION only - nothing writes to it. No managed session-content logging
# exists on OCI; this bucket is scaffolding for a self-built recorder.
resource "oci_objectstorage_bucket" "session_logs" {
  count = var.enable_session_recording ? 1 : 0

  compartment_id = var.compartment_id
  namespace      = local.namespace
  name           = local.session_log_bucket_name

  access_type = "NoPublicAccess"
  versioning  = "Enabled"
  kms_key_id  = var.bucket_kms_key_id

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_objectstorage_object_lifecycle_policy" "session_logs" {
  count = var.enable_session_recording ? 1 : 0

  namespace = local.namespace
  bucket    = oci_objectstorage_bucket.session_logs[0].name

  dynamic "rules" {
    for_each = var.session_log_archive_after_days != null ? [1] : []

    content {
      name        = "archive"
      action      = "ARCHIVE"
      target      = "objects"
      time_amount = tostring(var.session_log_archive_after_days)
      time_unit   = "DAYS"
      is_enabled  = true
    }
  }

  rules {
    name        = "expire"
    action      = "DELETE"
    target      = "objects"
    time_amount = tostring(var.session_log_retention_days)
    time_unit   = "DAYS"
    is_enabled  = true
  }
}
