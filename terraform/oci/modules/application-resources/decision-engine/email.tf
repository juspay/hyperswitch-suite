# Email Delivery - delegated to the shared email-delivery module.
#
# Mechanically identical to hyperswitch's email-delivery call (the cross-account
# STS hop disappears; a DNS-verified domain plus an approved sender are real
# objects).
#
# The decision-engine-specific point: this module and `hyperswitch` send as the
# same logical sender. `email.create` therefore defaults to FALSE here - set
# `email.use_existing_domain_id`/`use_existing_sender_id` from hyperswitch's
# outputs and this module creates nothing. This module exposes no SMTP fallback
# of its own - that belongs with the shared sender identity in hyperswitch.

module "email-delivery" {
  source = "../email-delivery"

  compartment_id = var.compartment_id
  region         = var.region
  freeform_tags  = local.freeform_tags
  defined_tags   = var.defined_tags

  email = var.email
}