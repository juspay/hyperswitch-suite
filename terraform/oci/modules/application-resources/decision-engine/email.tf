# =============================================================================
# Email Delivery (check sheet feature 8, SUBSTITUTE - section 4.2)
# =============================================================================
# Mechanically identical to hyperswitch's email.tf: the cross-account
# sts:AssumeRole hop into account 576373346466 disappears (nothing on OCI
# reproduces "borrow another tenancy's verified sender"), and a DNS-verified
# domain plus an approved sender become real objects in this tenancy.
#
# THE ONE decision-engine-SPECIFIC POINT: this module and `hyperswitch` send
# through the SAME AWS SES role today, i.e. as the same logical sender. Two
# verified OCI domains for one logical sender is duplicated DNS verification for
# no isolation benefit. Check sheet section 4.2 therefore recommends SHARING
# hyperswitch's domain and sender - set `email.use_existing_domain_id` /
# `use_existing_sender_id` from that module's outputs and create nothing here.
# That is the DEFAULT below (`create` defaults to false, unlike hyperswitch's
# true).
#
# It is also an oracle gate item (section 8 item 2) and NOT YET CONSULTED, so
# the create path is written and validated rather than removed - flipping to it
# is a `values` change, not a module change.
#
# The identity question is hyperswitch's, unchanged: the `use email-family`
# workload-identity grant is emitted unconditionally as the primary path;
# whether the HTTPS SubmitEmail endpoint honours a workload principal is
# hyperswitch.md section 9 Q1. This module deliberately exposes no SMTP
# fallback of its own - if that fallback is ever taken, it belongs with the
# shared sender identity in `hyperswitch`, not duplicated here.

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
