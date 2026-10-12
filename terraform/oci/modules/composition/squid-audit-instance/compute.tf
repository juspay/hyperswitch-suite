# The security team's standalone review box from the hardened Squid image: VPN-reachable
# private IP only, non-root review user, dedicated key supplied at apply time.

resource "oci_core_instance" "this" {
  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  fault_domain        = var.fault_domain
  display_name        = local.display_name
  shape               = var.shape

  shape_config {
    ocpus         = var.shape_ocpus
    memory_in_gbs = var.shape_memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = var.image_id
    boot_volume_size_in_gbs = tostring(var.boot_volume_size_in_gbs)
    kms_key_id              = var.boot_volume_kms_key_id
  }

  create_vnic_details {
    subnet_id = var.subnet_id
    # assign_public_ip is a STRING here (not a bool, as on instance_configuration).
    # No per-VNIC prohibit_public_ip_on_vnic exists - that is subnet-level
    # (management tier sets it true). So assign_public_ip = "false" plus the
    # subnet-level prohibition = no public IP, VPN-reachable private IP only.
    assign_public_ip = "false"
    nsg_ids          = local.nsg_ids
    display_name     = "${local.display_name}-vnic"
    hostname_label   = replace(local.display_name, "-", "")
    freeform_tags    = local.freeform_tags
  }

  metadata = local.instance_metadata

  # IMDSv2-equivalent hardening.
  instance_options {
    are_legacy_imds_endpoints_disabled = var.disable_legacy_imds_endpoints
  }

  agent_config {
    is_monitoring_disabled = true
    is_management_disabled = false

    # Keep the Compute Instance Management plugin enabled: Run Command (the W1
    # audit mechanism) requires it.
    plugins_config {
      name          = "Compute Instance Management"
      desired_state = "ENABLED"
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    ignore_changes = []

    # This disposable box is destroyed after audit; require preserve_boot_volume=false
    # so removal is deliberate, not a silent drift surprise.
    precondition {
      condition     = var.preserve_boot_volume == false
      error_message = "preserve_boot_volume must stay false: this is a disposable audit instance whose boot volume must be removed on termination. Set true only if you intend to keep it and know the billing consequence."
    }
  }
}