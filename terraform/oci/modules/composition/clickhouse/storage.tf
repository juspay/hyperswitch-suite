# =============================================================================
# Dual persistent data volumes per node (PARTIAL - check sheet feature 11, 4.4)
# =============================================================================
# FOUR volume CLASSES, not four volumes: keeper_data, keeper_data2, server_data,
# server_data2, each parameterized by its tier's count. Exactly the AWS module's
# shape, including lifecycle { prevent_destroy = true } on every one.
#
# The two-volume split is carried across deliberately rather than simplified.
# The AWS module gives no in-code reason for it and GCP's own port collapsed it
# to one disk per node; prod/eu-west-1 carries a `generate "import_volumes"`
# block importing pre-existing EBS volumes by ID, which is evidence the
# "attach the same data volumes to a fresh instance" operation has already
# happened at least once in production. Diverging from AWS here would be a data
# migration, not a refactor. Check sheet open question 9.1 owns the question of
# whether OCI should keep two; until it is answered, keeping two is the choice
# that cannot lose data.
#
# -----------------------------------------------------------------------------
# THE iSCSI DECISION - read this before changing data_volume_attachment_type
# -----------------------------------------------------------------------------
# CAPACITY IS NOT THE GAP. Balanced (10 VPU/GB) gives 60 IOPS/GB up to 25,000 per
# volume; Higher Performance 75 IOPS/GB up to 35,000; Ultra High Performance
# 90-225 IOPS/GB up to 300,000 and 2,680 MB/s. gp3's baseline is a flat 3,000
# IOPS / 125 MB/s. OCI's ceiling is well above what this workload asks for.
#
# THE ATTACHMENT MECHANISM IS THE GAP, and it has no AWS precedent:
#
#   paravirtualized - zero-touch, the block device appears in the guest with no
#                     in-guest action, exactly like EBS. Documented by Oracle as
#                     lower and less consistent IOPS.
#   iscsi           - "improved and more consistent IOPS", but the guest must
#                     register the target with `iscsiadm` and log in before the
#                     block device exists at all.
#
# This module DEFAULTS TO iscsi, because ClickHouse merge and compaction I/O is
# precisely the workload gp3's consistency was chosen for on AWS.
#
# WHAT THAT COSTS - A NEW FAILURE MODE WITH NO AWS INCIDENT HISTORY:
# a node can boot successfully, mount nothing, and serve queries from an empty
# filesystem, silently, until someone notices the data is gone. A reboot is as
# dangerous as a rebuild.
#
# Two mitigations, both needed:
#   1. is_agent_auto_iscsi_login_enabled = true below. VERIFIED PRESENT on
#      oci_core_volume_attachment in provider 9.0.0 (read from the provider's own
#      schema in-session). Oracle Cloud Agent performs the iscsiadm registration
#      and login, which removes most of the hand-rolled scripting the check
#      sheet's section 4.4 assumed. This is BETTER than the check sheet's stated
#      position and should be folded back into it.
#   2. The image's boot sequence must FAIL FAST if the expected mount is absent
#      rather than starting ClickHouse on whatever is there. That is an
#      image-pipeline requirement (vm-tier-and-images.md), not something this
#      module can enforce, and it is OUTSTANDING. Rung-6 smoke testing must
#      REBOOT a node, not only apply once - the initial apply does not exercise
#      this at all.
#
# What is NOT here: every *_device_name variable (/dev/sdb, /dev/sdc). AWS names
# the guest device from Terraform; an iSCSI-attached OCI volume's in-guest path
# is a function of the attach step, not a Terraform string. What path the image's
# ClickHouse config should expect is check sheet open question 9.2, UNRESOLVED,
# and it is a real seam between this module and the image pipeline.
#
# Check sheet section 8 item 4: ORACLE GATE ITEM, NOT YET CONSULTED.

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
    # Hardcoded, not var.prevent_data_volume_destroy: Terraform forbids a
    # variable inside a lifecycle block. Same constraint the AWS module hit.
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
