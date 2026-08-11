locals {
  name_prefix = "${var.environment}-${var.project_name}-jump"
}

# ============================================================================
# Logging (equivalent of AWS CloudWatch Log Group for jump host + SSM
# session logs)
# ============================================================================
resource "oci_logging_log_group" "jump_host" {
  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-logs"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Session recording bucket (equivalent of AWS aws_s3_bucket.ssm_session_logs).
# Session recording itself is provided by the OCI Bastion service
# (see README) - this bucket exists for teams that keep a persistent
# jump host (as this module does) and forward shell session logs to it.
resource "oci_objectstorage_bucket" "session_logs" {
  count = var.create_session_log_bucket ? 1 : 0

  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = "${local.name_prefix}-session-logs"

  versioning = "Disabled"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

data "oci_objectstorage_namespace" "this" {
  compartment_id = var.compartment_id
}

# ============================================================================
# IAM - Dynamic Group + Policy (equivalent of AWS IAM role with
# AmazonSSMManagedInstanceCore + CloudWatchAgentServerPolicy + inline
# CloudWatch/KMS/S3 policies)
# ============================================================================
resource "oci_identity_dynamic_group" "jump_host" {
  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-dynamic-group"
  description    = "Instance principal dynamic group for the jump host"
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_id}', tag.${var.environment}.jump-host.value = 'true'}"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_identity_policy" "jump_host" {
  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-policy"
  description    = "Policy for the jump host instance"

  statements = concat(
    [
      "Allow dynamic-group ${oci_identity_dynamic_group.jump_host.name} to use log-content in compartment id ${var.compartment_id}",
      "Allow dynamic-group ${oci_identity_dynamic_group.jump_host.name} to use metrics in compartment id ${var.compartment_id}",
    ],
    var.create_session_log_bucket ? [
      "Allow dynamic-group ${oci_identity_dynamic_group.jump_host.name} to manage objects in compartment id ${var.compartment_id} where target.bucket.name = '${local.name_prefix}-session-logs'",
    ] : [],
  )

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# Network Security Group
# ============================================================================
resource "oci_core_network_security_group" "jump_host" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-nsg"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# Jump Host Instance (using the official, verified
# oracle-terraform-modules/compute-instance/oci registry module)
# ============================================================================
module "jump_instance" {
  source  = "oracle-terraform-modules/compute-instance/oci"
  version = "2.4.1"

  compartment_ocid = var.compartment_id

  instance_count        = 1
  instance_display_name = local.name_prefix

  shape                       = var.shape
  instance_flex_ocpus         = var.instance_ocpus
  instance_flex_memory_in_gbs = var.instance_memory_in_gbs

  source_type = "image"
  source_ocid = var.image_id

  boot_volume_size_in_gbs = var.root_volume_size_in_gbs

  subnet_ocids         = [var.subnet_id]
  primary_vnic_nsg_ids = [oci_core_network_security_group.jump_host.id]
  assign_public_ip     = false

  ssh_authorized_keys = var.ssh_authorized_keys
  user_data           = var.user_data

  freeform_tags = merge(var.freeform_tags, { "${var.environment}.jump-host" = "true" })
  defined_tags  = var.defined_tags

  depends_on = [oci_logging_log_group.jump_host]
}
