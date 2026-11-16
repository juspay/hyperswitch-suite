terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Verified against oracle/oci 9.0.0. Every argument, block name and
    # enum used in this module was read out of that provider's own JSON
    # schema (`terraform providers schema -json`), not from memory.
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0"
    }
  }
}

# =============================================================================
# PROVIDERS DELIBERATELY *NOT* REQUIRED HERE - read this before adding one
# =============================================================================
#
# hashicorp/tls is ABSENT, and its absence is the single most important
# security decision in this module.
#
# The AWS locker (terraform/aws/modules/composition/locker/main.tf) generates
# an RSA-4096 keypair with `tls_private_key.locker` and copies the private half
# into `aws_ssm_parameter.locker_private_key`. `tls_private_key` is an ordinary
# resource, so `private_key_pem` is written to Terraform state in plaintext -
# there is no field-level state encryption. This is not hypothetical: the live
# catalog unit terraform/catalog/units/locker/terragrunt.hcl sets
# `create_key_pair = true` and never sets `public_key`, so the generate-and-
# persist branch is the one running in all 8 AWS live roots today
# (master-checksheet.md finding A1; oci/modules/locker.md section 4.2).
#
# This port does not reproduce it. See ACCESS.md-equivalent notes in README.md
# and in secrets.tf; the short form is:
#
#   * there is no VM in this module to log in to (see main-shape note in
#     database.tf), so there is nothing for an SSH key to authenticate to;
#   * interactive access to anything in the locker's subnets is OCI Bastion
#     (`oci_bastion_bastion` + short-lived `oci_bastion_session`), which is the
#     direct analogue of the AWS SSM Session Manager path the org already uses
#     in practice - the live AWS userdata sets SSH_SERVICE="SSM";
#   * if a key pair is ever genuinely needed, generate it with OCI Vault's own
#     server-side generator (`oci_vault_secret` with
#     `secret_generation_context { generation_type = "SSH_KEY",
#     generation_template = "RSA_4096" }`), NOT with `tls_private_key` and NOT
#     with `ephemeral "tls_private_key"`. Vault-side generation is strictly
#     stronger than either: the private key is produced inside the service and
#     never exists in a Terraform value, so it cannot reach state, a plan file,
#     or a CI log. `ephemeral "tls_private_key"` keeps the key out of state but
#     still requires the plaintext to transit the Terraform process on its way
#     to a durable store.
#
# hashicorp/random is ABSENT for the same reason. The shared
# composition/database module generates its admin password with
# `random_password` and accepts that the value lands in state; this module
# instead has OCI Vault generate the password server-side (secrets.tf). That is
# a deliberate, documented divergence from its sibling module, not an
# oversight.
