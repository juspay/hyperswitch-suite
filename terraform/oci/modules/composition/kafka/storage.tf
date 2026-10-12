# Dedicated data volumes
# Encryption at rest is always on with an Oracle-managed key; var.volume_kms_key_id
# only swaps in a customer key. Attachment type defaults to paravirtualized; if
# switched to iscsi, read ../cassandra/storage.tf's iSCSI note first - it
# documents a boot-time failure mode with no AWS precedent.

resource "oci_core_volume" "broker_data" {
  count = var.broker_count

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  display_name        = "${local.name_prefix}-broker-${count.index}-data"

  size_in_gbs = var.broker_data_volume_size_in_gbs

  # OCI sizes performance with a VPU tier, not a volume-type string: 10 VPU/GB
  # (Balanced) is 60 IOPS/GB, so a 100 GB volume already delivers 6,000 IOPS.
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

  # Only meaningful for iscsi - Oracle Cloud Agent does the iscsiadm login itself.
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
