# =============================================================================
# Dedicated key custody for the card vault (check sheet feature 14, FULL)
# =============================================================================
# Port of the AWS module's nested `terraform-aws-modules/kms/aws` 4.2.0. The
# capability survives intact - this is one of the few FULL verdicts in the
# sheet - but the OBJECT MODEL differs and the difference is load-bearing:
#
#   AWS  : aws_kms_key is a top-level object with an ARN and an attached JSON
#          key policy. Aliases are separate objects. A multi-region key is a
#          property of the key, and a replica is a second key resource.
#   OCI  : a key lives INSIDE a vault. The vault owns the management and crypto
#          endpoints, and oci_kms_key takes `management_endpoint` rather than a
#          vault id (`vault_id` is computed). There are no aliases. Access
#          control is IAM policy statements, not a document attached to the key.
#
# So AWS's single `module.kms` becomes two resources here, and `vault_id`
# appears in the output contract with no AWS counterpart.
#
# WHY THE LOCKER OWNS ITS OWN VAULT rather than reading the environment's
# shared one (include.root.locals.vault_id): identical reasoning to the AWS
# module creating its own KMS key instead of sharing the platform key, and to
# the GCP module creating its own keyring. This is the module holding
# cardholder data; its key custody boundary is the PCI-DSS scope boundary. A
# shared vault would put the card vault's keys and the general platform's keys
# under one set of IAM grants.
#
# HSM: protection_mode defaults to "HSM" and this module keeps it there. That
# matches AWS KMS's default posture. OCI additionally offers single-tenant HSM
# partition isolation via vault_type = "VIRTUAL_PRIVATE" - something plain AWS
# KMS cannot do without a CloudHSM custom key store - and var.vault.vault_type
# exposes it. It is NOT the default: it is materially more expensive and
# parity, not improvement, is this module's job. See check sheet section 10,
# "Key custody" row (verdict: Equal).

resource "oci_kms_vault" "locker" {
  count = local.create_vault ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = coalesce(var.vault.display_name, "${local.name_prefix}-vault")

  # DEFAULT = multi-tenant HSM partition (the AWS KMS equivalent).
  # VIRTUAL_PRIVATE = dedicated partition; see the header note.
  vault_type = var.vault.vault_type

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # A deleted vault takes every key in it, and a key deleted with backups
    # still encrypted under it makes those backups permanently unreadable -
    # the same reasoning that put prevent_destroy on the GCP module's keyring.
    # Terraform forbids a variable here, so this is hardcoded and a deliberate
    # teardown is a two-step (comment out on a branch, apply, then destroy).
    #
    # Note also that OCI vault deletion is SCHEDULED, not immediate: a deleted
    # vault sits in PENDING_DELETION for 7-30 days and its display name is not
    # reusable until it purges. Recreating this module after a destroy inside
    # that window fails on a name collision, not on anything Terraform can see.
    prevent_destroy = true
  }
}

resource "oci_kms_key" "locker" {
  count = local.create_key ? 1 : 0

  compartment_id      = var.compartment_id
  display_name        = coalesce(var.kms_key.display_name, "${local.name_prefix}-key")
  management_endpoint = local.management_endpoint

  # AWS's customer_master_key_spec = SYMMETRIC_DEFAULT. Note the unit: OCI
  # expresses AES key length in BYTES (16/24/32), not bits, so 32 is AES-256.
  key_shape {
    algorithm = var.kms_key.algorithm
    length    = var.kms_key.length
  }

  # HSM by default - see the header note.
  protection_mode = var.kms_key.protection_mode

  # AWS: enable_key_rotation = true (default) with rotation_period_in_days.
  # OCI: same capability, narrower window - 60 to 365 days, validated in
  # variables.tf. Neither cloud disables rotation by default.
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

# -----------------------------------------------------------------------------
# Cross-region vault replication - AWS's kms.multi_region / create_replica
# -----------------------------------------------------------------------------
# The AWS locker's passive-region pattern (catalog/stacks/passive) sets
# multi_region = true on the primary and creates a replica key in the passive
# region, so the passive database can be encrypted under the "same" key.
#
# OCI's analogue replicates the whole VAULT, not a single key, and the replica
# is created by a separate resource pointed at the primary. Two consequences
# worth knowing before using it:
#
#   1. It is vault-granular. Replicating for one key replicates every key in
#      the vault - which is an argument FOR this module owning a dedicated
#      vault rather than sharing the platform's.
#   2. It buys less here than it does on AWS, because the thing the AWS replica
#      key exists to encrypt - the passive Aurora cluster's storage - has no
#      customer-key argument on OCI at all (see database.tf, feature 17,
#      PARTIAL). What a replica vault can still protect cross-region is this
#      module's own Vault SECRETS.
#
# Off by default. Turning it on is a `values` change in the passive stack.
resource "oci_kms_vault_replication" "locker" {
  count = local.create_vault && var.vault.replica_region != null ? 1 : 0

  vault_id       = oci_kms_vault.locker[0].id
  replica_region = var.vault.replica_region
}
