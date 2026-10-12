# Node fleet - self-managed Cassandra, as on AWS (no managed OCI alternative exists).

resource "oci_core_instance" "cassandra" {
  count = var.node_count

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain

  # One node per fault domain - the only in-region fault isolation (ap-mumbai-1 has one AD).
  fault_domain = local.node_fault_domain[count.index]

  display_name = "${local.name_prefix}-${count.index}"
  shape        = var.shape

  # OCPU is a PHYSICAL core (two vCPUs on x86 SMT), so a vCPU count must not be copied across.
  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  source_details {
    source_type = "image"
    source_id   = var.image_id

    # Boot volume is deleted with the instance by default.
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
    boot_volume_vpus_per_gb = var.boot_volume_vpus_per_gb

    # Encryption at rest is always on with an Oracle-managed key; this only swaps in a customer key.
    kms_key_id = var.volume_kms_key_id
  }

  create_vnic_details {
    subnet_id                 = var.subnet_id
    display_name              = "${local.name_prefix}-${count.index}-vnic"
    assign_public_ip          = "false"
    assign_private_dns_record = var.assign_private_dns_record
    nsg_ids                   = local.nsg_ids

    freeform_tags = local.freeform_tags
    defined_tags  = var.defined_tags
  }

  # base64 cloud-init, read by the guest from the token-gated (IMDSv2-equivalent) OCI metadata service.
  metadata = local.instance_metadata

  instance_options {
    # Equivalent of metadata_options.http_tokens = "required". OCI exposes
    # instance tags to the guest unconditionally - keep secrets out of tags.
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
    # Load-bearing for the reserved-IP re-point in network.tf: the replacement
    # VNIC must exist before the private IP can move onto it.
    create_before_destroy = true

    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"],
      defined_tags["Oracle-Tags.CreatedBy"],
    ]
  }
}
