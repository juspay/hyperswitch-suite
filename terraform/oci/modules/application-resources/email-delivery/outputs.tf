output "email_domain_id" {
  description = "OCID of the verified email domain, whether created here or supplied via use_existing_domain_id."
  value       = local.email_domain_id
}

output "email_sender_id" {
  description = "OCID of the approved sender."
  value       = local.email_sender_id
}

output "email_sender_address" {
  description = "The approved from-address."
  value       = try(var.email.sender_address, null)
}

output "email_uses_static_credential_fallback" {
  description = <<-EOT
    TRUE means this deployment is NOT sending mail under workload identity.

    It flips only when `smtp_credential_vault_secret_id` is set, i.e. when an
    operator has provisioned an SMTP credential out of band because workload
    identity was not available on the HTTPS send path. That is a long-lived,
    user-bound, manually-rotated credential and therefore an accepted regression
    against the identity model - surfaced here, in the plan and in every
    consumer's outputs, precisely so it cannot be taken silently.
  EOT
  value       = var.smtp_credential_vault_secret_id != null
}

output "smtp_credential_vault_secret_id" {
  description = "Echo of the Vault secret OCID holding the SMTP fallback credential, for an ExternalSecret to project into the pod. The OCID only - this module never reads, stores or emits the credential value."
  value       = var.smtp_credential_vault_secret_id
}