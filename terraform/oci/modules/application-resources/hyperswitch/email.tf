# Email Delivery - delegated to the shared email-delivery module.
#
# The domain + approved sender were extracted out of this module into
# terraform/oci/modules/application-resources/email-delivery so `hyperswitch`
# and `decision-engine` describe one logical sender once. This call keeps the
# workload-identity path primary: `email_uses_static_credential_fallback` stays
# false unless an operator opts into the SMTP credential fallback via
# `smtp_credential_vault_secret_id`.

module "email-delivery" {
  source = "../email-delivery"

  compartment_id = var.compartment_id
  region         = var.region
  freeform_tags  = local.freeform_tags
  defined_tags   = var.defined_tags

  email = var.email

  smtp_credential_vault_secret_id = var.smtp_credential_vault_secret_id
}