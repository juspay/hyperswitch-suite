# Output contract

output "policy_statements" {
  description = <<-EOT
    This module's contribution to the ONE shared, environment-scoped
    `oci_identity_policy` owned by the `oke-workload-identity` unit. Rendered,
    normalised and sorted; ready to be concatenated into that unit's
    `statements` input without further processing.

    THIS MODULE CREATES NO POLICY OBJECT. `oci_identity_policy.name` is
    tenancy-unique and non-updatable, and one object per app per live root is
    132 objects against a hard limit of 100.
    Do not wrap this list in a policy resource in the caller either; hand it to
    `oke-workload-identity`, which owns the single object, enforces the
    50-statement cap and re-validates every `where` condition at plan time.

    Read it, do not skim it: this list is the security boundary in full. Expect
    7 statements per cluster per service account with
    every feature on (6 when `functions.enabled` is false on a passive stack).
  EOT
  value       = local.policy_statements
}

output "statement_count" {
  description = "Number of statements this module contributes, against the shared policy object's hard 50-statement ceiling."
  value       = length(local.policy_statements)
}

output "authorized_workloads" {
  description = "Every (cluster_id, namespace, service_account) tuple these statements authorise. The replacement for the AWS module's `cluster_service_accounts` echo - for auditing the rendered statements, not for consumption by a workload."
  value       = local.authorized_workloads
}

output "kms_vault_id" {
  description = "OCID of the Vault holding the key. No AWS counterpart - AWS keys live on a regional service with no enclosing object. This is what `oci_kms_vault_replication` targets, and what a passive-region stack reads instead of AWS's `kms_key_arn`."
  value       = one(oci_kms_vault.this[*].id)
}

output "kms_vault_type" {
  description = "DEFAULT or VIRTUAL_PRIVATE. Surfaced because it is NOT updatable in place and because cross-region replication requires VIRTUAL_PRIVATE - a standing dedicated-HSM cost."
  value       = local.kms_create ? local.vault_type : null
}

output "kms_vault_management_endpoint" {
  description = "Vault management endpoint. Required by any other module creating a key in this vault; OCI has no regional service endpoint to fall back on."
  value       = one(oci_kms_vault.this[*].management_endpoint)
}

output "kms_vault_crypto_endpoint" {
  description = "Vault crypto endpoint - where encrypt/decrypt calls go. AWS's equivalent is implicit in the regional KMS endpoint."
  value       = one(oci_kms_vault.this[*].crypto_endpoint)
}

output "kms_key_id" {
  description = "OCID of the customer-managed key, whether created here or supplied via kms.existing_key_id. THE CONSUMED OUTPUT: `superposition` and `decision-engine` both grant `use keys` scoped to this OCID, exactly as they read `kms_key_arn` today. Replaces kms_key_arn and kms_key_id together - one OCID does the work of both."
  value       = local.kms_key_id
}

output "kms_replica_enabled" {
  description = "Whether a cross-region vault replica was created. Replaces AWS's kms_replica_key_arn with a boolean, because OCI replicates the VAULT and publishes no separate replica-key identifier this module can export."
  value       = local.kms_replica_create
}

output "object_storage_namespace" {
  description = "The tenancy's Object Storage namespace. No AWS counterpart - S3 bucket names are globally unique, OCI's are unique within this namespace, and every consuming API call needs it explicitly."
  value       = data.oci_objectstorage_namespace.this.namespace
}

output "dashboard_themes_bucket_name" {
  description = "Dashboard-themes bucket name. Replaces AWS s3_dashboard_themes_bucket_id/_arn - OCI addresses a bucket by (namespace, name), so there is no ARN to emit."
  value       = one(oci_objectstorage_bucket.dashboard_themes[*].name)
}

output "file_uploads_bucket_name" {
  description = "File-uploads bucket name. Replaces AWS s3_file_uploads_bucket_id/_arn."
  value       = one(oci_objectstorage_bucket.file_uploads[*].name)
}

output "email_domain_id" {
  description = "OCID of the verified email domain, whether created here or supplied. `decision-engine` should consume THIS rather than verifying a second domain for the same logical sender - a sharing decision that is not yet reviewed."
  value       = module.email-delivery.email_domain_id
}

output "email_sender_id" {
  description = "OCID of the approved sender. AWS's ses.role_arn has no counterpart - there is no role, and the sender is a first-class object in this tenancy rather than an identity borrowed from another account."
  value       = module.email-delivery.email_sender_id
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
    identity was not available on the HTTPS send path.
    That is a long-lived, user-bound, manually-rotated credential and therefore
    an accepted regression against the identity model - surfaced
    here, in the plan and in every consumer's outputs, precisely so it cannot be
    taken silently.
  EOT
  value       = module.email-delivery.email_uses_static_credential_fallback
}

output "smtp_credential_vault_secret_id" {
  description = "Echo of the Vault secret OCID holding the SMTP fallback credential, for an ExternalSecret to project into the pod. The OCID only - this module never reads, stores or emits the credential value."
  value       = var.smtp_credential_vault_secret_id
}

output "secrets_enabled" {
  description = "Whether the Vault read grants (`read secret-bundles` + `read secrets`) were emitted."
  value       = local.secrets_enabled
}

output "functions_enabled" {
  description = "Whether the `use functions-family` grant was emitted. Mirrors the AWS unit's own `lambda.enabled = !is_passive`."
  value       = local.functions_enabled
}

output "compartment_id" {
  description = "Compartment these resources live in, and the default location term of every statement emitted. Must be at or below the compartment the shared policy is attached to."
  value       = var.compartment_id
}

output "region" {
  description = "Region, echoed from the input. Unchanged from AWS."
  value       = var.region
}
