# =============================================================================
# SSH key pair and private-key escrow (check sheet feature 7, FULL)
# =============================================================================
# tls_private_key is unchanged - key generation is cloud-agnostic. What changes:
# there is no aws_key_pair object on OCI (the public key is a metadata line), and
# escrow moves from SSM Parameter Store to OCI Vault, which needs a pre-existing
# Vault AND KMS key. While either is null nothing is written and the private key
# exists only in Terraform state - which makes the state backend's encryption
# load-bearing. Check sheet open question 9.2 on kafka.md, UNRESOLVED.

resource "tls_private_key" "cassandra" {
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
    content      = base64encode(tls_private_key.cassandra[0].private_key_pem)
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
