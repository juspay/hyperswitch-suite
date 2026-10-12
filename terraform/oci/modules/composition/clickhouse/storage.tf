# Dual persistent data volumes per node
# FOUR volume classes (keeper_data/data2, server_data/data2), each
# prevent_destroy = true. The two-volume split is carried from AWS deliberately -
# diverging would be a data migration, not a refactor.
#
# iSCSI by default (ClickHouse merge/compaction I/O is the workload gp3's
# consistency was chosen for). New failure mode with no AWS precedent: a node can
# boot, mount nothing, and serve from an empty filesystem, silently, until
# someone notices the data is gone; a reboot is as dangerous as a rebuild.
# Mitigations: is_agent_auto_iscsi_login_enabled = true below (Oracle Cloud Agent
# does the iscsiadm login), and the image's boot sequence must FAIL FAST if the
# expected mount is absent (an image-pipeline requirement, still OUTSTANDING;
# rung-6 smoke testing must REBOOT a node).

resource "oci_core_volume" "keeper_data" {
  count = var.keeper_count

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  display_name        = "${local.name_prefix}-keeper-${count.index}-data"

  size_in_gbs = var.keeper_data_volume_size_in_gbs
  vpus_per_gb = var.keeper_data_volume_vpus_per_gb
  kms_key_id  = var.volume_kms_key_id

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # Hardcoded, not a variable: Terraform forbids a variable in a lifecycle block.
    prevent_destroy = true
  }
}

resource "oci_core_volume_attachment" "keeper_data" {
  count = var.keeper_count

  attachment_type = var.data_volume_attachment_type
  instance_id     = oci_core_instance.keeper[count.index].id
  volume_id       = oci_core_volume.keeper_data[count.index].id
  display_name    = "${local.name_prefix}-keeper-${count.index}-data-att"

  is_agent_auto_iscsi_login_enabled = var.data_volume_attachment_type == "iscsi" ? true : null
}

resource "oci_core_volume" "keeper_data2" {
  count = var.keeper_count

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  display_name        = "${local.name_prefix}-keeper-${count.index}-data2"

  size_in_gbs = var.keeper_data2_volume_size_in_gbs
  vpus_per_gb = var.keeper_data2_volume_vpus_per_gb
  kms_key_id  = var.volume_kms_key_id

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_volume_attachment" "keeper_data2" {
  count = var.keeper_count

  attachment_type = var.data_volume_attachment_type
  instance_id     = oci_core_instance.keeper[count.index].id
  volume_id       = oci_core_volume.keeper_data2[count.index].id
  display_name    = "${local.name_prefix}-keeper-${count.index}-data2-att"

  is_agent_auto_iscsi_login_enabled = var.data_volume_attachment_type == "iscsi" ? true : null
}

resource "oci_core_volume" "server_data" {
  count = var.server_count

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  display_name        = "${local.name_prefix}-server-${count.index}-data"

  size_in_gbs = var.server_data_volume_size_in_gbs
  vpus_per_gb = var.server_data_volume_vpus_per_gb
  kms_key_id  = var.volume_kms_key_id

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_volume_attachment" "server_data" {
  count = var.server_count

  attachment_type = var.data_volume_attachment_type
  instance_id     = oci_core_instance.server[count.index].id
  volume_id       = oci_core_volume.server_data[count.index].id
  display_name    = "${local.name_prefix}-server-${count.index}-data-att"

  is_agent_auto_iscsi_login_enabled = var.data_volume_attachment_type == "iscsi" ? true : null
}

resource "oci_core_volume" "server_data2" {
  count = var.server_count

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  display_name        = "${local.name_prefix}-server-${count.index}-data2"

  size_in_gbs = var.server_data2_volume_size_in_gbs
  vpus_per_gb = var.server_data2_volume_vpus_per_gb
  kms_key_id  = var.volume_kms_key_id

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_volume_attachment" "server_data2" {
  count = var.server_count

  attachment_type = var.data_volume_attachment_type
  instance_id     = oci_core_instance.server[count.index].id
  volume_id       = oci_core_volume.server_data2[count.index].id
  display_name    = "${local.name_prefix}-server-${count.index}-data2-att"

  is_agent_auto_iscsi_login_enabled = var.data_volume_attachment_type == "iscsi" ? true : null
}
