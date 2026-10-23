# One shared OCI Email Delivery domain + approved sender pair.
#
# Extracted from the inline `email.tf` that `hyperswitch` and `decision-engine`
# each carried, so one logical sender is described once and consumed by both.
# A DNS-verified domain plus an approved sender are real OCI objects; there is
# no AWS-style cross-account SES role to assume, so the cross-account hop is
# deliberately absent.

resource "oci_email_email_domain" "this" {
  count = local.email_create ? 1 : 0

  compartment_id = var.compartment_id
  name           = var.email.domain_name

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_email_sender" "this" {
  count = local.email_create ? 1 : 0

  compartment_id = var.compartment_id
  email_address  = var.email.sender_address

  freeform_tags = var.freeform_tags
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

resource "oci_email_dkim" "this" {
  count = local.email_dkim_enabled ? 1 : 0

  email_domain_id = local.email_domain_id
  name            = try(var.email.dkim_selector, null)

  # compartment_id is not configurable on oci_email_dkim; it is inherited from
  # the email domain.
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  # DKIM is a signing key under the domain, so it is created only after the
  # domain exists. Referencing email_domain_id pins the ordering; depends_on
  # makes it explicit and robust to OCID-string graph inference.
  depends_on = [oci_email_email_domain.this]
}
