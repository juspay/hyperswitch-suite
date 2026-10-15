locals {
  email_enabled = coalesce(var.email.enabled, true)
  email_create  = local.email_enabled && coalesce(var.email.create, true) && var.email.use_existing_domain_id == null

  email_domain_id = local.email_create ? one(oci_email_email_domain.this[*].id) : var.email.use_existing_domain_id
  email_sender_id = local.email_create ? one(oci_email_sender.this[*].id) : var.email.use_existing_sender_id
}