# =============================================================================
# bastion-host - the jump-host port
# =============================================================================
# Renamed from AWS's `jump-host`, following the precedent GCP already set
# (terraform/gcp/modules/composition/bastion-host/) for the same reason: the
# module is now a thin wrapper around a specific, named cloud service - OCI's
# Bastion, just as GCP's wraps IAP tunnelling - not a generic "a box you jump
# through". Naming it after the AWS module would bury that in every future
# reader's first impression. Check sheet §5.
#
# One instance, not a pool: this module's AWS original is a single
# ec2-instance, and its access path IS its reason to exist rather than one
# feature among many.

# -----------------------------------------------------------------------------
# The jump instance (FULL - check sheet feature 1)
# -----------------------------------------------------------------------------
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

  # kms_key_id null = Oracle-managed boot-volume encryption, the mapping for
  # the AWS module's root_block_device.encrypted = true. Default-encrypted
  # behaviour is Tier 2 pending confirmation (check sheet open question 5).
  source_details {
    source_type             = "image"
    source_id               = var.image_id
    boot_volume_size_in_gbs = tostring(var.boot_volume_size_in_gbs)
    kms_key_id              = var.boot_volume_kms_key_id
  }

  create_vnic_details {
    subnet_id = var.subnet_id
    # assign_public_ip is a STRING on oci_core_instance (not a bool as it is on
    # oci_core_instance_configuration) - a real inconsistency in the provider,
    # not a typo here.
    assign_public_ip = var.assign_public_ip ? "true" : "false"
    nsg_ids          = local.nsg_ids
    display_name     = "${local.display_name}-vnic"
    hostname_label   = replace(local.display_name, "-", "")
    freeform_tags    = local.freeform_tags
  }

  # FULL - check sheet feature 11. templates/userdata.sh ports from AWS with no
  # logic changes; cloud-init reads it at /opc/v2/instance/metadata/ exactly as
  # an EC2 instance reads a launch template's user_data.
  metadata = local.instance_metadata

  instance_options {
    are_legacy_imds_endpoints_disabled = var.disable_legacy_imds_endpoints
  }

  agent_config {
    is_monitoring_disabled = false
    is_management_disabled = false

    # Only needed for Managed SSH sessions, which this module deliberately does
    # not use - see the session-type comment on oci_bastion_bastion below.
    # Enabled anyway so an operator who needs Managed SSH is not blocked on a
    # reboot.
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
    # The image is the boot artefact, not the running state. Replacing this
    # instance on an image bump is correct and cheap (it holds no data), so
    # nothing is ignored here - unlike the pooled proxy modules, where the
    # autoscaling service owns the size.
    ignore_changes = []
  }
}

# -----------------------------------------------------------------------------
# OCI Bastion (SUBSTITUTE - check sheet feature 2)
# -----------------------------------------------------------------------------
# THIS IS NOT SSM SESSION MANAGER WITH A DIFFERENT NAME. Read this before
# assuming parity, because the differences are concrete:
#
#   1. KEYS. Every OCI Bastion session requires an SSH keypair -
#      key_details.public_key_content is a REQUIRED argument on
#      oci_bastion_session. SSM needs no key of any kind, ever, under any
#      configuration.
#
#   2. INBOUND RULES. Every session type still needs an inbound rule on the
#      target from the bastion's private endpoint IP. SSM needs zero, because
#      its agent only makes outbound calls. See network.tf.
#
#   3. SESSION CONTENT LOGGING. None exists. OCI Audit records
#      CreateSession/DeleteSession - who, when, against which target - and
#      nothing about what happened inside the session. SSM optionally records a
#      full replayable transcript. See var.enable_session_recording; the gap is
#      NONE, not PARTIAL, and the mitigation is self-built tooling.
#
#   4. TRANSPORT. SSM brokers a WebSocket data channel; OCI Bastion brokers an
#      SSH connection. An SSH session is encrypted end to end by SSH itself,
#      which is a DIFFERENT trust model rather than a strictly weaker one - so
#      the absence of a KMS-session-encryption knob is arguably moot, unlike
#      items 1-3, which are losses.
#
# What survives: centrally brokered, time-boxed, IAM-gated access to a
# private-subnet host with no permanently open SSH port to the internet. That
# outcome is real. The mechanism is not the same one.
#
# SESSION TYPE. No oci_bastion_session is created here, deliberately. Sessions
# are short-lived, per-operator, per-incident objects - Terraform-managing one
# would mean an operator's SSH public key living in state and a session whose
# lifetime is an apply rather than an incident. The connection guide output
# tells operators to create a PORT_FORWARDING session, which is the correct
# type for a fixed, known jump target: Managed SSH exists to reach ARBITRARY
# instances without standing SSH access configured on them, and this box's
# whole purpose is being the one hop operators tunnel THROUGH. Check sheet §4.
resource "oci_bastion_bastion" "this" {
  count = var.create_bastion ? 1 : 0

  compartment_id   = var.compartment_id
  bastion_type     = "STANDARD"
  name             = replace("${local.display_name}", "-", "_")
  target_subnet_id = local.bastion_target_subnet_id

  # New surface with no AWS counterpart: AWS gates Session Manager on IAM alone
  # and has no CIDR control over who may start a session. See the variable.
  client_cidr_block_allow_list = var.bastion_client_cidr_allow_list

  # PARTIAL - a session-LIFETIME cap, not the idle timer AWS's
  # idleSessionTimeout preference is. No idle-specific control was found.
  max_session_ttl_in_seconds = var.bastion_max_session_ttl_seconds

  # Lets a port-forwarding session target a hostname rather than only an IP -
  # which is what makes tunnelling to the data tier's private FQDNs work.
  dns_proxy_status = var.bastion_dns_proxy_status

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# -----------------------------------------------------------------------------
# Host log group and log (FULL - check sheet feature 6)
# -----------------------------------------------------------------------------
# oci_logging_log_group is a compartment-scoped container, directly analogous
# to aws_cloudwatch_log_group. The AWS module creates two log groups: one for
# host logs and one for SSM session content. Only the host one has a
# counterpart here - there is no session content to route anywhere.
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
# Self-managed session-recording archive (NONE - check sheet features 3 and 4)
# -----------------------------------------------------------------------------
# A DESTINATION, and nothing that writes to it. See var.enable_session_recording
# for the full accounting; the short version is that OCI has no managed
# session-content logging to enable, so this bucket is honest scaffolding for a
# recorder the platform would have to build, deploy through the same cloud-init
# path used for SSH hardening, and then monitor for silent failure.
#
# The lifecycle policy half IS full parity with the AWS module's Glacier
# lifecycle - ARCHIVE is Glacier's counterpart. Only the thing being archived
# is the gap.
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
