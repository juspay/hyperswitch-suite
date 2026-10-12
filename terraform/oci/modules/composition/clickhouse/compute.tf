# =============================================================================
# Keeper tier (check sheet feature 1, SELF-MANAGED)
# =============================================================================
# ClickHouse Keeper is ClickHouse's own Raft coordination service - the role
# ZooKeeper plays for older deployments and KRaft plays for ../kafka.
#
# SELF-MANAGED is PARITY: the AWS original runs both tiers on raw EC2. There is
# no managed alternative to weigh - ClickHouse Cloud is third-party SaaS, not an
# OCI-native service - so self-managing is the only path on all three clouds.
# Check sheet section 8 item 1, gate NOT YET CONSULTED.
#
# keeper_count = 0 is supported and creates nothing in this tier, matching the
# AWS module's "use an externally-provided Keeper cluster" path.

resource "oci_core_instance" "keeper" {
  count = var.keeper_count

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain

  # One Keeper per fault domain. ap-mumbai-1 has ONE availability domain, so a
  # 3-node Raft quorum survives a rack or host failure but NOT a whole-AD event.
  # Check sheet section 8 item 5: ORACLE GATE ITEM, NOT YET CONSULTED.
  fault_domain = local.keeper_fault_domain[count.index]

  display_name = "${local.name_prefix}-keeper-${count.index}"
  shape        = var.keeper_shape

  shape_config {
    ocpus         = var.keeper_ocpus
    memory_in_gbs = var.keeper_memory_in_gbs
  }

  source_details {
    source_type = "image"
    source_id   = var.keeper_image_id

    # Ephemeral by design (check sheet feature 10): the boot volume is deleted
    # with the instance by default, already matching AWS's root_block_device
    # delete_on_termination = true. The persistent data lives on the separately
    # managed, destroy-protected volumes in storage.tf.
    boot_volume_size_in_gbs = var.keeper_boot_volume_size_in_gbs
    boot_volume_vpus_per_gb = var.keeper_boot_volume_vpus_per_gb

    kms_key_id = var.volume_kms_key_id
  }

  create_vnic_details {
    subnet_id                 = var.keeper_subnet_id
    display_name              = "${local.name_prefix}-keeper-${count.index}-vnic"
    assign_public_ip          = "false"
    assign_private_dns_record = var.assign_private_dns_record
    nsg_ids                   = local.keeper_nsg_ids

    freeform_tags = local.freeform_tags
    defined_tags  = var.defined_tags
  }

  metadata = local.keeper_metadata

  instance_options {
    are_legacy_imds_endpoints_disabled = var.are_legacy_imds_endpoints_disabled
  }

  agent_config {
    is_monitoring_disabled = !var.enable_monitoring_plugin
    is_management_disabled = false

    dynamic "plugins_config" {
      for_each = local.agent_plugins
      content {
        name          = plugins_config.value.name
        desired_state = plugins_config.value.desired_state
      }
    }
  }

  availability_config {
    recovery_action = var.recovery_action
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # Load-bearing for the reserved-IP re-point in network.tf.
    create_before_destroy = true

    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"],
      defined_tags["Oracle-Tags.CreatedBy"],
    ]
  }
}

# =============================================================================
# Keeper-before-server ordering
# =============================================================================
# NOT a port - the AWS module has no equivalent gate. Added because ClickHouse
# servers that start before the Keeper quorum forms fail their first coordination
# round, the same class of problem ../kafka's time_sleep.wait_for_controller
# exists to prevent. Set keeper_startup_delay_seconds = 0 to disable.

resource "time_sleep" "wait_for_keeper" {
  count = var.keeper_count > 0 ? 1 : 0

  depends_on = [oci_core_instance.keeper]

  create_duration = "${var.keeper_startup_delay_seconds}s"

  triggers = {
    keeper_ids = join(",", oci_core_instance.keeper[*].id)
  }
}

# =============================================================================
# Server tier (check sheet feature 2, SELF-MANAGED)
# =============================================================================

resource "oci_core_instance" "server" {
  count = var.server_count

  depends_on = [time_sleep.wait_for_keeper]

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  fault_domain        = local.server_fault_domain[count.index]

  display_name = "${local.name_prefix}-server-${count.index}"
  shape        = var.server_shape

  shape_config {
    ocpus         = var.server_ocpus
    memory_in_gbs = var.server_memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = var.server_image_id
    boot_volume_size_in_gbs = var.server_boot_volume_size_in_gbs
    boot_volume_vpus_per_gb = var.server_boot_volume_vpus_per_gb
    kms_key_id              = var.volume_kms_key_id
  }

  create_vnic_details {
    subnet_id                 = var.server_subnet_id
    display_name              = "${local.name_prefix}-server-${count.index}-vnic"
    assign_public_ip          = "false"
    assign_private_dns_record = var.assign_private_dns_record
    nsg_ids                   = local.server_nsg_ids

    freeform_tags = local.freeform_tags
    defined_tags  = var.defined_tags
  }

  metadata = local.server_metadata

  instance_options {
    are_legacy_imds_endpoints_disabled = var.are_legacy_imds_endpoints_disabled
  }

  agent_config {
    is_monitoring_disabled = !var.enable_monitoring_plugin
    is_management_disabled = false

    dynamic "plugins_config" {
      for_each = local.agent_plugins
      content {
        name          = plugins_config.value.name
        desired_state = plugins_config.value.desired_state
      }
    }
  }

  availability_config {
    recovery_action = var.recovery_action
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    create_before_destroy = true

    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"],
      defined_tags["Oracle-Tags.CreatedBy"],
    ]
  }
}
