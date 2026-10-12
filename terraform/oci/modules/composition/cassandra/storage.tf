# =============================================================================
# Dedicated data volume per node (check sheet feature 3, FULL)
# =============================================================================
# One volume per node, unlike ../clickhouse's two - the simpler case of the same
# pattern. AWS declares this as an ebs_block_device inside aws_instance with
# `encrypted = true`; on OCI a block volume is always a separate object plus an
# attachment, and encryption at rest is on by default with no opt-out.
#
# -----------------------------------------------------------------------------
# THE iSCSI DECISION - read this before changing data_volume_attachment_type
# -----------------------------------------------------------------------------
# CAPACITY IS NOT THE GAP. Balanced (10 VPU/GB) already gives 60 IOPS/GB up to
# 25,000 per volume; Higher Performance 75 IOPS/GB up to 35,000; Ultra High
# Performance 90-225 IOPS/GB up to 300,000. gp3's baseline is a flat 3,000 IOPS.
# A 200 GB Balanced volume beats gp3 four times over with no extra provisioning.
#
# THE ATTACHMENT MECHANISM IS THE GAP, and it has no AWS precedent at all. OCI
# offers exactly two attachment types:
#
#   paravirtualized - zero-touch. The block device appears in the guest with no
#                     in-guest action, exactly the way an EBS volume does. Oracle
#                     documents it as lower and less consistent IOPS.
#   iscsi           - "improved and more consistent IOPS", but the guest must
#                     register the target with `iscsiadm` and log in before the
#                     block device exists at all.
#
# This module DEFAULTS TO iscsi, because Cassandra's commit-log and compaction
# I/O is exactly the workload gp3's consistency was chosen for on AWS.
#
# WHAT THAT COSTS, stated plainly because it is a NEW FAILURE MODE:
# a node can boot successfully, mount nothing, and run Cassandra on an empty
# root filesystem - silently - until someone notices the data is gone. There is
# no AWS-side incident history to have shaken this out.
#
# Two mitigations, and both are needed:
#   1. is_agent_auto_iscsi_login_enabled = true below. VERIFIED PRESENT on
#      oci_core_volume_attachment in provider 9.0.0 (read from the provider's own
#      schema in-session). Oracle Cloud Agent performs the iscsiadm registration
#      and login itself, which removes most of the hand-rolled scripting the
#      check sheet's section 4.4 assumed would be required. This is BETTER than
#      the check sheet's stated position and should be folded back into it.
#   2. The image's boot sequence must still FAIL FAST if the expected mount is
#      absent, rather than starting the service on whatever is there. That is an
#      image-pipeline requirement (vm-tier-and-images.md), not something this
#      module can enforce, and it is outstanding.
#
# Also note what is NOT here: ebs_device_name. AWS names the guest device
# (/dev/sdh) from Terraform. An iSCSI-attached OCI volume's in-guest path is a
# function of the attach step, not of a Terraform-supplied string, so the
# variable is dropped rather than renamed. What path the image's Cassandra config
# should expect is check sheet open question 9.2 / clickhouse 9.2, UNRESOLVED.
#
# Check sheet section 8 item 4 (shared with clickhouse): ORACLE GATE ITEM,
# NOT YET CONSULTED.

resource "oci_core_volume" "data" {
  count = var.node_count

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  display_name        = "${local.name_prefix}-${count.index}-data"

  size_in_gbs = var.data_volume_size_in_gbs

  # Replaces ebs_volume_type = "gp3" - OCI sizes performance with a VPU tier,
  # not a volume-type string.
  vpus_per_gb = var.data_volume_vpus_per_gb

  kms_key_id = var.volume_kms_key_id

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # The AWS module does not protect this volume, but it also rebuilds nodes
    # rarely. Replacing an instance here must not take the ring's data with it.
    prevent_destroy = true
  }
}

resource "oci_core_volume_attachment" "data" {
  count = var.node_count

  attachment_type = var.data_volume_attachment_type
  instance_id     = oci_core_instance.cassandra[count.index].id
  volume_id       = oci_core_volume.data[count.index].id
  display_name    = "${local.name_prefix}-${count.index}-data-att"

  # Only meaningful for iscsi. See the long note above - this is mitigation 1
  # of 2 for the silent-empty-filesystem failure mode.
  is_agent_auto_iscsi_login_enabled = var.data_volume_attachment_type == "iscsi" ? true : null
}
