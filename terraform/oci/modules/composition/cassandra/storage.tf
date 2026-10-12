# Dedicated data volume per node.
# DEFAULTS TO iSCSI attachment for Cassandra's commit-log/compaction IOPS consistency.
# NEW FAILURE MODE with no AWS precedent: without the auto-login mitigation below a
# node can boot, mount nothing, and run Cassandra on an empty root filesystem
# silently. Two mitigations are needed and present: (1) the auto-iSCSI-login agent
# flag on the attachment, and (2) an image-boot fail-fast check, which is an
# image-pipeline requirement this module cannot enforce.

resource "oci_core_volume" "data" {
  count = var.node_count

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  display_name        = "${local.name_prefix}-${count.index}-data"

  size_in_gbs = var.data_volume_size_in_gbs

  # OCI sizes performance with a VPU tier, not a volume-type string.
  vpus_per_gb = var.data_volume_vpus_per_gb

  kms_key_id = var.volume_kms_key_id

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # Replacing an instance must not take the ring's data with it.
    prevent_destroy = true
  }
}

resource "oci_core_volume_attachment" "data" {
  count = var.node_count

  attachment_type = var.data_volume_attachment_type
  instance_id     = oci_core_instance.cassandra[count.index].id
  volume_id       = oci_core_volume.data[count.index].id
  display_name    = "${local.name_prefix}-${count.index}-data-att"

  # Only meaningful for iscsi - mitigation 1 of 2 for the silent-empty-filesystem failure mode.
  is_agent_auto_iscsi_login_enabled = var.data_volume_attachment_type == "iscsi" ? true : null
}
