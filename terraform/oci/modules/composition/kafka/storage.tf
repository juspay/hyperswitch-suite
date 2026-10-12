# =============================================================================
# Dedicated data volumes (check sheet feature 8 / 10, FULL)
# =============================================================================
# AWS declares these as ebs_block_device blocks inside aws_instance, with
# `encrypted = true` set explicitly. On OCI a block volume is always a separate
# object plus an attachment, and encryption at rest is on by default with no
# opt-out - so the AWS `encrypted` argument has no counterpart to port, and the
# only key decision left is Oracle-managed vs var.volume_kms_key_id.
#
# ATTACHMENT TYPE: see var.data_volume_attachment_type. Kafka defaults to
# paravirtualized (zero-touch, the EBS-like behaviour); cassandra and clickhouse
# in this same wave default to iscsi because their check sheets call for the
# gp3-equivalent IOPS floor. If this fleet is ever switched to iscsi, read
# ../cassandra/storage.tf's iSCSI note first - it documents a boot-time failure
# mode with no AWS precedent.

resource "oci_core_volume" "broker_data" {
  count = var.broker_count

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  display_name        = "${local.name_prefix}-broker-${count.index}-data"

  size_in_gbs = var.broker_data_volume_size_in_gbs

  # Replaces broker_data_volume_type = "gp3". OCI sizes performance with a VPU
  # tier rather than a volume-type string: 10 VPU/GB (Balanced) is 60 IOPS/GB,
  # so a 100 GB volume already delivers 6,000 IOPS against gp3's 3,000 baseline.
  vpus_per_gb = var.broker_data_volume_vpus_per_gb

  kms_key_id = var.volume_kms_key_id

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_volume_attachment" "broker_data" {
  count = var.broker_count

  attachment_type = var.data_volume_attachment_type
  instance_id     = oci_core_instance.broker[count.index].id
  volume_id       = oci_core_volume.broker_data[count.index].id
  display_name    = "${local.name_prefix}-broker-${count.index}-data-att"

  # Only meaningful for iscsi. Oracle Cloud Agent performs the iscsiadm
  # registration and login itself when this is true, which removes most - but
  # not all - of the guest-side scripting an iSCSI attachment otherwise needs.
  is_agent_auto_iscsi_login_enabled = var.data_volume_attachment_type == "iscsi" ? true : null
}

resource "oci_core_volume" "controller_metadata" {
  count = var.controller_count

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  display_name        = "${local.name_prefix}-controller-${count.index}-metadata"

  size_in_gbs = var.controller_metadata_volume_size_in_gbs
  vpus_per_gb = var.controller_metadata_volume_vpus_per_gb
  kms_key_id  = var.volume_kms_key_id

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_volume_attachment" "controller_metadata" {
  count = var.controller_count

  attachment_type = var.data_volume_attachment_type
  instance_id     = oci_core_instance.controller[count.index].id
  volume_id       = oci_core_volume.controller_metadata[count.index].id
  display_name    = "${local.name_prefix}-controller-${count.index}-metadata-att"

  is_agent_auto_iscsi_login_enabled = var.data_volume_attachment_type == "iscsi" ? true : null
}
