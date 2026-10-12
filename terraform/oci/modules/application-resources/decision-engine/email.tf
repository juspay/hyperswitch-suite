# Email Delivery
# Mechanically identical to hyperswitch's email.tf (the cross-account STS hop
# disappears; a DNS-verified domain plus an approved sender are real objects).
#
# THE decision-engine-specific point: this module and `hyperswitch` send as the
# same logical sender. Sharing hyperswitch's domain/sender is therefore the
# default - set `email.use_existing_domain_id`/`use_existing_sender_id` from
# that module's outputs, and create nothing here (`create` defaults to false).
# Owning a second verified domain for one logical sender is duplicated DNS
# verification for no isolation benefit. The create path stays written so
# flipping to it is a `values` change. This module exposes no SMTP fallback of
# its own - that belongs with the shared sender identity in `hyperswitch`.

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

  depends_on = [oci_email_email_domain.this]

  lifecycle {
    precondition {
      condition     = var.email.domain_name == null || endswith(lower(var.email.sender_address), "@${lower(var.email.domain_name)}")
      error_message = "email.sender_address must be an address under email.domain_name. OCI approved senders live under a verified domain in the same tenancy."
    }
  }
}
