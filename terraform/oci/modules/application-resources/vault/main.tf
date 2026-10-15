# One dedicated DEFAULT OCI Vault and one symmetric AES-256 master key.

# THIS MODULE DOES NOT CREATE A POLICY, a dynamic group, any secret content, or
# any Kubernetes identity. On OCI an `oci_identity_policy` IS the grant (its
# statements name the subject at creation time), and the platform runs ONE
# shared policy object per environment owned by `oke-workload-identity`, into
# which the ESO module contributes statements. The Vault module's job is
# narrower: claim the Vault + key object pair (both of which ESO's SecretStore
# references by OCID) and nothing else.

resource "oci_kms_vault" "this" {
  compartment_id = var.compartment_id
  display_name   = var.display_name

  # vault_type is NOT updatable in place - changing it forces replacement of
  # the vault, every key in it, and every secret. This is the platform's
  # secrets vault; a single-region DEFAULT vault is correct for this sandbox.
  # Cross-region replication (DR) is NOT a supported feature for the secret
  # delivery path yet; when it becomes one the caller must pass
  # vault_type = "VIRTUAL_PRIVATE", not this module's job to guess.
  vault_type = "DEFAULT"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_kms_key" "this" {
  compartment_id = var.compartment_id
  display_name   = var.key_display_name

  # Key operations go to the vault's own endpoint, so the key cannot be created
  # before the vault exists.
  management_endpoint = oci_kms_vault.this.management_endpoint

  key_shape {
    algorithm = "AES"
    length    = 32
  }

  # Software protection is correct for the sandbox. HSM protection ("HSM") is
  # only relevant when the key never leaves a hardware boundary; the ESO
  # operator decrypts secret bundles at rest, so SOFTWARE keeps the change.
  protection_mode = "SOFTWARE"

  is_auto_rotation_enabled = var.enable_key_rotation

  dynamic "auto_key_rotation_details" {
    for_each = var.enable_key_rotation ? [1] : []

    content {
      rotation_interval_in_days = var.rotation_interval_in_days
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    prevent_destroy = true
  }
}