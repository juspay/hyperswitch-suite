# =============================================================================
# ONE standalone instance - the audit box
# =============================================================================
# A single oci_core_instance, deliberately NOT a pool/configuration/autoscaling
# chain. This is the security-team's disposable review host from the freshly
# built hardened Ubuntu 24.04 squid image.
#
# The review user (non-root, sudo, SSH-key-only, ufw limited to tcp:22 from the
# VPN ranges) is created by templates/userdata.sh at boot, mirroring the GCP
# `secreview` review-VM pattern. The key is provided at apply time via
# var.ssh_public_key; it is never baked into the image or the module.

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
    # assign_public_ip is a STRING on oci_core_instance (not a bool, as on
    # oci_core_instance_configuration). There is no `prohibit_public_ip_on_vnic`
    # argument on a VNIC's create_vnic_details - that is a subnet-level
    # attribute, and the `management` tier ALREADY sets it true (vpc-network
    # locals.tf). So the per-VNIC control is assign_public_ip = "false" with the
    # subnet-level prohibition as belt-and-braces. No public IP, VPN-reachable
    # private IP only.
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

    precondition {
      condition     = var.preserve_boot_volume == false
      error_message = "preserve_boot_volume must stay false: this is a disposable audit instance whose boot volume must be removed on termination. Set true only if you intend to keep it and know the billing consequence."
    }
  }
}