locals {
  email_enabled = coalesce(var.email.enabled, true)
  email_create  = local.email_enabled && coalesce(var.email.create, true) && var.email.use_existing_domain_id == null

  email_dkim_enabled = local.email_create && coalesce(var.email.dkim_enabled, false)

  email_domain_id = local.email_create ? one(oci_email_email_domain.this[*].id) : var.email.use_existing_domain_id
  email_sender_id = local.email_create ? one(oci_email_sender.this[*].id) : var.email.use_existing_sender_id
  email_dkim_id   = local.email_dkim_enabled ? one(oci_email_dkim.this[*].id) : null
}
