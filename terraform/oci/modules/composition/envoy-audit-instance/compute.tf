# =============================================================================
# ONE standalone instance - the audit box
# =============================================================================
# A single oci_core_instance, deliberately NOT a pool/configuration/autoscaling
# chain. This is the security-team's disposable review host from the freshly
# built hardened Ubuntu 24.04 envoy image.
#
# The shape of this resource (source_details from image, create_vnic_details in
# the VPN-reachable management tier, metadata carrying the review user + the
# security team's key, instance_options hardening, no public IP) is the
# bastion-host module's standalone-instance idiom, minus everything the review
# box does not need.
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

  # source_details FROM the hardened image. kms_key_id null = Oracle-managed
  # boot-volume encryption, the mapping for ebs_encrypted = true. boot_volume_size
  # is a string on this resource, not a number.
  source_details {
    source_type             = "image"
    source_id               = var.image_id
    boot_volume_size_in_gbs = tostring(var.boot_volume_size_in_gbs)
    kms_key_id              = var.boot_volume_kms_key_id
  }

  create_vnic_details {
    subnet_id = var.subnet_id
    # assign_public_ip is a STRING on oci_core_instance (not the bool it is on
    # oci_core_instance_configuration) - a real inconsistency in the provider.
    #
    # There is no `prohibit_public_ip_on_vnic` argument on a VNIC's
    # create_vnic_details - that attribute is subnet-level, and the `management`
    # tier ALREADY sets prohibit_public_ip_on_vnic = true (vpc-network
    # locals.tf). So the per-VNIC control here is assign_public_ip = "false",
    # and the subnet-level prohibition is the belt-and-braces underneath it. The
    # audit instance has no public IP and is reached over the VPN by private IP
    # only - strictly the envoy tier's stance.
    assign_public_ip = "false"
    nsg_ids          = local.nsg_ids
    display_name     = "${local.display_name}-vnic"
    hostname_label   = replace(local.display_name, "-", "")
    freeform_tags    = local.freeform_tags
  }

  metadata = local.instance_metadata

  # IMDSv2-equivalent hardening - disables the unauthenticated /opc/v1/ endpoints.
  instance_options {
    are_legacy_imds_endpoints_disabled = var.disable_legacy_imds_endpoints
  }

  agent_config {
    is_monitoring_disabled = true
    is_management_disabled = false

    # Keep the Oracle Cloud Agent management plugin enabled: Run Command (the
    # audit workflow's W1 mechanism, workplan section 5) requires it.
    plugins_config {
      name          = "Compute Instance Management"
      desired_state = "ENABLED"
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # The image is the boot artefact, not the running state. Replacing this
    # instance on an image bump is correct and cheap (it holds no data).
    ignore_changes = []

    # The terminate-after-audit lifecycle is the whole point of this box. The
    # operator destroys it after W1; this precondition makes it a deliberate,
    # explicit action rather than a silent drift surprise.
    precondition {
      condition     = var.preserve_boot_volume == false
      error_message = "preserve_boot_volume must stay false: this is a disposable audit instance whose boot volume must be removed on termination. Set true only if you intend to keep it and know the billing consequence."
    }
  }
}