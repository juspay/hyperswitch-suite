# Customer-managed encryption key

resource "oci_kms_vault" "this" {
  count = local.kms_create ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = coalesce(var.kms.vault_display_name, "${local.name_prefix}-vault")

  # vault_type is NOT updatable in place - changing it forces replacement of the
  # vault and every key in it. Cross-region replication requires VIRTUAL_PRIVATE,
  # so the type is driven off the DR posture rather than an independent boolean.
  vault_type = local.vault_type

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_kms_key" "this" {
  count = local.kms_create ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = coalesce(var.kms.key_display_name, "${local.name_prefix}-key")

  # Key operations go to the vault's own endpoint, so the key cannot be created
  # before the vault exists.
  management_endpoint = oci_kms_vault.this[0].management_endpoint

  key_shape {
    algorithm = var.kms.key_algorithm
    length    = var.kms.key_length
  }

  protection_mode = var.kms.protection_mode

  # Rotation interval range is 60-365 days on OCI; the 365 default sits at its top.
  is_auto_rotation_enabled = var.kms.enable_key_rotation

  dynamic "auto_key_rotation_details" {
    for_each = var.kms.enable_key_rotation ? [1] : []

    content {
      rotation_interval_in_days = var.kms.rotation_interval_in_days
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# Cross-region replica
resource "oci_kms_vault_replication" "this" {
  count = local.kms_replica_create ? 1 : 0

  vault_id       = oci_kms_vault.this[0].id
  replica_region = var.kms.replica_region

  lifecycle {
    precondition {
      condition     = var.kms.replica_region != null
      error_message = "kms.replica_region is required when kms.create_replica is true."
    }

    precondition {
      condition     = var.kms.replica_region != var.region
      error_message = "kms.replica_region must differ from the vault's own region."
    }
  }
}
