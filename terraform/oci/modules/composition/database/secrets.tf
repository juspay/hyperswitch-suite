# OCI Vault storage for the generated admin password (only when the module
# owns a secret). OCI's VAULT_SECRET reads a caller-created secret and never
# rotates it, so the module generates the value. Nothing here is ever a literal
# password - the value is either generated or handed in by the caller. Skipped
# entirely for a warm standby, which inherits the primary's users.

resource "oci_vault_secret" "admin_password" {
  count = local.vault_secret_create ? 1 : 0

  compartment_id = var.compartment_id
  vault_id       = var.vault_secret.vault_id

  # Required by oci_vault_secret: OCI Vault takes a customer-managed key for
  # the CREDENTIAL, while the database's data at rest cannot. This is the only
  # part of the key-custody story this module can actually tell.
  key_id = var.vault_secret.key_id

  secret_name = local.vault_secret_name
  description = "Admin password for ${local.display_name}"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(local.admin_password)
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
