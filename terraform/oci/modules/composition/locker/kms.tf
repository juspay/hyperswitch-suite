# Dedicated key custody for the card vault. On OCI a key lives INSIDE a vault:
# the vault owns the management/crypto endpoints and oci_kms_key takes
# management_endpoint rather than a vault id. Access control is IAM policy
# statements, not a document attached to the key.
# This module owns its OWN vault - a shared vault would put the card vault's
# keys and the platform's keys under one set of IAM grants, which would cross
# the PCI-DSS scope boundary.
# HSM is the default (AWS KMS's posture); vault_type VIRTUAL_PRIVATE offers
# dedicated single-tenant HSM isolation, and is NOT the default (it is
# materially more expensive and parity, not improvement, is the goal).

resource "oci_kms_vault" "locker" {
  count = local.create_vault ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = coalesce(var.vault.display_name, "${local.name_prefix}-vault")

  # DEFAULT = multi-tenant HSM partition (the AWS KMS equivalent).
  # VIRTUAL_PRIVATE = dedicated partition; see the header.
  vault_type = var.vault.vault_type

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # A deleted vault takes every key in it, and a key deleted with backups
    # still encrypted under it makes those backups permanently unreadable.
    # Terraform forbids a variable here, so it is hardcoded; deliberate teardown
    # is a two-step (comment out on a branch, apply, then destroy). OCI vault
    # deletion is SCHEDULED (7-30 days) and the display name is not reusable
    # until it purges - recreating right after a destroy fails on a collision.
    prevent_destroy = true
  }
}

resource "oci_kms_key" "locker" {
  count = local.create_key ? 1 : 0

  compartment_id      = var.compartment_id
  display_name        = coalesce(var.kms_key.display_name, "${local.name_prefix}-key")
  management_endpoint = local.management_endpoint

  # OCI expresses AES key length in BYTES (16/24/32), not bits; 32 is AES-256.
  key_shape {
    algorithm = var.kms_key.algorithm
    length    = var.kms_key.length
  }

  # HSM by default - see the header note.
  protection_mode = var.kms_key.protection_mode

  # Same rotation capability, narrower window (60-365 days than AWS; neither
  # cloud disables rotation by default.
  is_auto_rotation_enabled = var.kms_key.auto_rotation_interval_in_days != null

  dynamic "auto_key_rotation_details" {
    for_each = var.kms_key.auto_rotation_interval_in_days != null ? [1] : []
    content {
      rotation_interval_in_days = var.kms_key.auto_rotation_interval_in_days
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    prevent_destroy = true
  }
}

# Cross-region vault replication. OCI replicates the whole VAULT, not a single
# key, so: (1) it is vault-granular - replicating for one key replicates every
# key in the vault, an argument FOR this module owning a dedicated vault; and
# (2) it buys less than on AWS because the passive cluster's storage has no
# customer-key argument at all. Off by default; a `values` change in the passive
# stack turns it on.
resource "oci_kms_vault_replication" "locker" {
  count = local.create_vault && var.vault.replica_region != null ? 1 : 0

  vault_id       = oci_kms_vault.locker[0].id
  replica_region = var.vault.replica_region
}
