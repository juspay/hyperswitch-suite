# Email Delivery

resource "oci_email_email_domain" "this" {
  count = local.email_create ? 1 : 0

  compartment_id = var.compartment_id
  name           = var.email.domain_name

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_email_sender" "this" {
  count = local.email_create ? 1 : 0

  compartment_id = var.compartment_id
  email_address  = var.email.sender_address

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # The sender must sit under the verified domain. Ordering is expressed as a
  # real dependency rather than left to Terraform's graph inference, because the
  # sender's address is a plain string and carries no reference to the domain
  # resource.
  depends_on = [oci_email_email_domain.this]

  lifecycle {
    precondition {
      condition     = var.email.domain_name == null || endswith(lower(var.email.sender_address), "@${lower(var.email.domain_name)}")
      error_message = "email.sender_address must be an address under email.domain_name. OCI approved senders live under a verified domain in the same tenancy; there is no cross-domain or cross-tenancy sender."
    }
  }
}

# Workload identity is the only path minted here: no user, API key or SMTP
# credential is created. A static SMTP-credential fallback is opt-in only,
# operator-provisioned out of band, and passed in as a Vault secret OCID - this
# module never sees a credential value. Taking it flips
# email_uses_static_credential_fallback so it appears in every consumer's plan.
locals {
  email_uses_static_credential_fallback = var.smtp_credential_vault_secret_id != null
}
