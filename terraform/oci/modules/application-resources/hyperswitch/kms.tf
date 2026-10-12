# =============================================================================
# Customer-managed encryption key (check sheet features 2 and 3)
# =============================================================================
# AWS: `module.kms` (terraform-aws-modules/kms/aws 4.2.0) + a separate
# `aws_iam_policy.kms_policy` attached to the role. On OCI the key is a Vault
# object and the permission is a POLICY STATEMENT, emitted from locals.tf - so
# there is no policy resource in this file and no key-policy argument to set.
# `oci_kms_key` has no equivalent of AWS's key_administrators / key_users /
# key_service_users lists; access to a key is granted the same way access to
# anything else on OCI is granted.

resource "oci_kms_vault" "this" {
  count = local.kms_create ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = coalesce(var.kms.vault_display_name, "${local.name_prefix}-vault")

  # ---------------------------------------------------------------------------
  # SUBSTITUTE - check sheet section 4.1.
  #
  # AWS multi-region KMS keys are ordinary objects on the shared KMS service:
  # `multi_region = true` is a boolean with no tier change and no extra fixed
  # cost. OCI's `oci_kms_vault_replication` is documented as "This only supports
  # virtual private vault for now" and "This supports only one replica in a
  # region for a vault" - a virtual private vault is the dedicated-HSM-partition
  # tier, a standing commitment even where no DR replica is needed.
  #
  # `vault_type` is NOT updatable in place: changing it forces replacement of
  # the vault, and therefore of every key in it. So it is decided here, once,
  # per environment, before the first apply - driven off the DR posture rather
  # than left as an independent boolean someone can forget to set. dev, with
  # create_replica = false, gets a DEFAULT vault and pays nothing for a replica
  # it does not have.
  # ---------------------------------------------------------------------------
  vault_type = local.vault_type

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_kms_key" "this" {
  count = local.kms_create ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = coalesce(var.kms.key_display_name, "${local.name_prefix}-key")

  # Unlike AWS, key operations go to the vault's own endpoint rather than a
  # regional service endpoint. This is why the key cannot be created before the
  # vault exists, and why an "existing key" is passed as an OCID rather than
  # being looked up by alias - OCI has no key-alias concept to replace AWS's
  # `aliases` input with.
  management_endpoint = oci_kms_vault.this[0].management_endpoint

  key_shape {
    algorithm = var.kms.key_algorithm
    length    = var.kms.key_length
  }

  protection_mode = var.kms.protection_mode

  # AWS's `enable_key_rotation = true` (annual) maps directly. OCI's documented
  # interval range is 60-365 days, so the AWS default sits at the top of it.
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

# -----------------------------------------------------------------------------
# Cross-region replica (check sheet feature 3, SUBSTITUTE)
# -----------------------------------------------------------------------------
# AWS creates a REPLICA KEY in the second region (`create_replica` +
# `primary_key_arn`), a first-class object with its own ARN that the passive
# stack reads. OCI replicates the VAULT, not the key: one resource, one replica
# region, and the replica is reached through the replicated vault rather than
# through an identifier this module can export. There is no growth path to a
# third region on the same vault.
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
