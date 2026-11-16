# =============================================================================
# SSH key pair and private-key escrow (check sheet feature 7, FULL)
# =============================================================================
# tls_private_key is unchanged from the AWS module - key generation is
# cloud-agnostic. Two things do change:
#
#   * there is no aws_key_pair object. OCI has no key-pair resource at all; the
#     public key is a line in instance metadata (ssh_authorized_keys), which is
#     why local.key_pair_name is a label rather than a resource reference.
#   * escrow moves from SSM Parameter Store (a flat namespace the module writes
#     into directly) to OCI Vault, which requires a pre-existing Vault AND a
#     pre-existing KMS key. When either is missing nothing is written and the
#     private key lives only in Terraform state - so the state backend's
#     encryption becomes load-bearing. The dev root has vault_id = null today
#     (check sheet open question 9.2, UNRESOLVED).

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
