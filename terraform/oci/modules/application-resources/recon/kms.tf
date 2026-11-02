# Recon's own customer-managed key - AWS: `module.kms`
# (`terraform-aws-modules/kms/aws` 4.2.0) + `aws_iam_policy.recon_kms`.
# Same shape as the hyperswitch module's kms.tf: the key lives inside a vault
# (AWS keys have no enclosing object), and access is granted only through
# policy statements (locals.tf), never on the key itself.

resource "oci_kms_vault" "this" {
  count = local.kms_create ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = coalesce(var.kms.vault_display_name, "${local.name_prefix}-recon-vault")

  vault_type = local.vault_type

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_kms_key" "this" {
  count = local.kms_create ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = coalesce(var.kms.key_display_name, "${local.name_prefix}-recon-key")

  management_endpoint = oci_kms_vault.this[0].management_endpoint

  key_shape {
    algorithm = var.kms.key_algorithm
    length    = var.kms.key_length
  }

  protection_mode = var.kms.protection_mode

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

# The OCI form of the AWS multi-region replica key (create_replica on a passive
# stack): the VAULT is replicated, not the key.
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
