# Controller tier
# Controllers are created FIRST and gated by time_sleep below.

resource "oci_core_instance" "controller" {
  count = var.controller_count

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain

  # One controller per fault domain. ap-mumbai-1 has ONE availability domain, so
  # this tolerates a rack or host failure, NOT a whole-AD event.
  fault_domain = local.controller_fault_domain[count.index]

  display_name = "${local.name_prefix}-controller-${count.index}"
  shape        = var.controller_shape

  # Flexible shapes decouple OCPU and memory from the shape name. OCPU is a
  # PHYSICAL core (2 vCPUs on an SMT x86 shape).
  shape_config {
    ocpus         = var.controller_ocpus
    memory_in_gbs = var.controller_memory_in_gbs
  }

  source_details {
    source_type = "image"
    source_id   = var.controller_image_id

    # Boot volume is deleted with the instance by default.
    boot_volume_size_in_gbs = var.controller_boot_volume_size_in_gbs
    boot_volume_vpus_per_gb = var.controller_boot_volume_vpus_per_gb

    # Encryption at rest is ALWAYS on with an Oracle-managed key; this only swaps
    # in a customer key.
    kms_key_id = var.volume_kms_key_id
  }

  create_vnic_details {
    subnet_id                 = var.controller_subnet_id
    display_name              = "${local.name_prefix}-controller-${count.index}-vnic"
    assign_public_ip          = "false"
    assign_private_dns_record = var.assign_private_dns_record
    nsg_ids                   = local.controller_nsg_ids

    freeform_tags = local.freeform_tags
    defined_tags  = var.defined_tags
  }

  # metadata.user_data is base64-encoded cloud-init read via the token-gated
  # IMDSv2-analogue metadata service.
  metadata = local.controller_metadata

  # Disables the legacy /v1 instance metadata endpoints (forces token-gated IMDS).
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
    # Load-bearing for the reserved-private-IP re-pointing in network.tf: the
    # replacement instance and its VNIC must exist before the private IP can be
    # moved onto it.
    create_before_destroy = true

    ignore_changes = [
      # metadata is rewritten on every apply by base64 encoding; the content is
      # what matters and it is stable.
      defined_tags["Oracle-Tags.CreatedOn"],
      defined_tags["Oracle-Tags.CreatedBy"],
    ]
  }
}

# Deterministic bootstrap ordering
# Brokers that start before the KRaft controller quorum forms fail their first
# metadata fetch.

resource "time_sleep" "wait_for_controller" {
  depends_on = [oci_core_instance.controller]

  create_duration = "${var.controller_startup_delay_seconds}s"

  triggers = {
    controller_ids = join(",", oci_core_instance.controller[*].id)
  }
}

# Broker tier

resource "oci_core_instance" "broker" {
  count = var.broker_count

  depends_on = [time_sleep.wait_for_controller]

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  fault_domain        = local.broker_fault_domain[count.index]

  display_name = "${local.name_prefix}-broker-${count.index}"
  shape        = var.broker_shape

  shape_config {
    ocpus         = var.broker_ocpus
    memory_in_gbs = var.broker_memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = var.broker_image_id
    boot_volume_size_in_gbs = var.broker_boot_volume_size_in_gbs
    boot_volume_vpus_per_gb = var.broker_boot_volume_vpus_per_gb
    kms_key_id              = var.volume_kms_key_id
  }

  create_vnic_details {
    subnet_id                 = var.broker_subnet_id
    display_name              = "${local.name_prefix}-broker-${count.index}-vnic"
    assign_public_ip          = "false"
    assign_private_dns_record = var.assign_private_dns_record
    nsg_ids                   = local.broker_nsg_ids

    freeform_tags = local.freeform_tags
    defined_tags  = var.defined_tags
  }

  metadata = local.broker_metadata

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
