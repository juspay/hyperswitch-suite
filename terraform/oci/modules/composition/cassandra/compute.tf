# =============================================================================
# Node fleet (check sheet feature 1, SELF-MANAGED)
# =============================================================================
# SELF-MANAGED is PARITY, not a regression: the AWS original runs Cassandra on
# raw EC2 too. Unlike ../kafka there is no managed alternative to weigh - no
# managed Cassandra-compatible OCI service exists, and third-party managed
# Cassandra is in retreat industry-wide. Self-managing is the only path on all
# three clouds. Check sheet section 8 item 1 is a formality-level gate item,
# NOT YET CONSULTED.

resource "oci_core_instance" "cassandra" {
  count = var.node_count

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain

  # One node per fault domain. ap-mumbai-1 has ONE availability domain, so this
  # is the only fault isolation available in-region: it survives a rack or host
  # failure, NOT a whole-AD event. A 3-node ring with RF=3 therefore has no
  # AD-level durability story in this region; cross-region (ap-hyderabad-1) is
  # the only real mitigation and is out of this module's scope.
  # Check sheet section 8 item 5: ORACLE GATE ITEM, NOT YET CONSULTED.
  fault_domain = local.node_fault_domain[count.index]

  display_name = "${local.name_prefix}-${count.index}"
  shape        = var.shape

  # AWS's single instance_type becomes three arguments. OCPU is a PHYSICAL core
  # (two vCPUs on an SMT x86 shape), so copying a vCPU count across as an OCPU
  # count doubles the machine.
  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  source_details {
    source_type = "image"
    source_id   = var.image_id

    # Boot volume is deleted with the instance by default, matching AWS's
    # root_block_device delete_on_termination = true.
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
    boot_volume_vpus_per_gb = var.boot_volume_vpus_per_gb

    # Encryption at rest is always on with an Oracle-managed key and there is no
    # opt-out; this only swaps in a customer key. AWS's `encrypted = true` has no
    # counterpart to port.
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

  # base64 cloud-init, read by the guest from
  # http://169.254.169.254/opc/v2/instance/metadata/ - the "v2" segment is the
  # token-gated (IMDSv2-equivalent) service.
  metadata = local.instance_metadata

  instance_options {
    # Equivalent of metadata_options.http_tokens = "required". The AWS module's
    # instance_metadata_tags = "enabled" has NO counterpart: OCI exposes instance
    # tags to the guest unconditionally, a wider default than AWS's opt-in. Keep
    # secrets out of tags on this fleet.
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
    # and its VNIC must exist before the private IP can move onto it.
    create_before_destroy = true

    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"],
      defined_tags["Oracle-Tags.CreatedBy"],
    ]
  }
}
