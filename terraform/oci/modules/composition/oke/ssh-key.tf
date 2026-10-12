# =============================================================================
# oke - SSH key for worker-node access (AWS feature 18)
# =============================================================================
# PARTIAL. eks.md gap 4.7.
#
# The AWS module generates an RSA keypair with `tls_private_key` when no public
# key is supplied and writes the private half to SSM Parameter Store as a
# SecureString. `oracle-terraform-modules/oke/oci` accepts `ssh_public_key` /
# `ssh_private_key` for an ALREADY-EXISTING key only: it neither generates nor
# persists one. So the two resources are added here, outside the registry
# module, targeting OCI Vault - the SSM SecureString analogue named in
# provider-facts.md's Tier 2 table.
#
# HONEST LIMITATION, do not read this as an improvement over AWS. Routing the
# private key to Vault means the operational retrieval path is Vault rather
# than Terraform state, but `tls_private_key` still materialises the private key
# INSIDE Terraform state, exactly as the AWS module does. The state backend's
# encryption and access control remain the real control. If a key that never
# touches Terraform state is required, generate it out of band and pass
# `ssh_public_key` with `create_ssh_key = false`.
# =============================================================================

resource "tls_private_key" "node_pool" {
  count = var.create_ssh_key ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096

  lifecycle {
    precondition {
      condition     = var.ssh_key_vault_id != null && var.ssh_key_kms_key_id != null
      error_message = "create_ssh_key = true requires both ssh_key_vault_id and ssh_key_kms_key_id so the generated private key has somewhere to be stored. OCI Vault is this programme's analogue of AWS SSM Parameter Store's SecureString tier."
    }
  }
}

resource "oci_vault_secret" "node_pool_private_key" {
  count = var.create_ssh_key ? 1 : 0

  compartment_id = var.compartment_id
  vault_id       = var.ssh_key_vault_id
  key_id         = var.ssh_key_kms_key_id

  secret_name = format("%s-node-ssh-private-key", local.cluster_name)
  description = format("OpenSSH private key for %s worker nodes. Analogue of the AWS module's aws_ssm_parameter.node_group_private_key.", local.cluster_name)

  secret_content {
    content_type = "BASE64"
    content      = base64encode(tls_private_key.node_pool[0].private_key_openssh)
  }

  freeform_tags = local.common_freeform_tags

  lifecycle {
    ignore_changes = [defined_tags]
  }
}
