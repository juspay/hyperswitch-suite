# SSH key pair and private-key escrow
# The public key is a line in instance metadata (no key-pair resource), and
# escrow goes to OCI Vault, which needs a pre-existing Vault AND KMS key. When
# either is missing the private key lives only in Terraform state, making state
# encryption load-bearing.

resource "tls_private_key" "kafka" {
  count = local.generate_key ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "oci_vault_secret" "ssh_private_key" {
  count = local.vault_secret_create ? 1 : 0

  compartment_id = var.compartment_id
  vault_id       = var.vault_secret.vault_id
  key_id         = var.vault_secret.key_id

  secret_name = local.vault_secret_name
  description = "SSH private key for ${local.name_prefix}"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(tls_private_key.kafka[0].private_key_pem)
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
