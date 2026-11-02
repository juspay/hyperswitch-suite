# Output contract - role_arn / role_name, the *_policy_arn outputs and the
# global-cluster outputs have no OCI counterpart (no role, no policy objects,
# no global cluster).

# -----------------------------------------------------------------------------
# THE IDENTITY CONTRACT
# -----------------------------------------------------------------------------

output "policy_statements" {
  description = <<-EOT
    This module's contribution to the ONE shared, environment-scoped
    `oci_identity_policy` owned by the `oke-workload-identity` unit. Rendered,
    normalised and sorted.

    THIS MODULE CREATES NO POLICY OBJECT. Hand this list to
    `oke-workload-identity`; do not wrap it in a policy resource in the caller.

    Expect 4 statements per cluster per service account with every feature on
    (`use keys`, `manage objects`, `read secret-bundles`, `read secrets`), plus
    anything in `extra_statements`.
  EOT
  value       = local.policy_statements
}

output "statement_count" {
  description = "Number of statements contributed, against the shared policy object's hard 50-statement ceiling."
  value       = length(local.policy_statements)
}

output "authorized_workloads" {
  description = "Every (cluster_id, namespace, service_account) tuple these statements authorise. For audit, not for consumption."
  value       = local.authorized_workloads
}

# -----------------------------------------------------------------------------
# KMS
# -----------------------------------------------------------------------------

output "kms_vault_id" {
  description = "OCID of the Vault holding the key. No AWS counterpart - AWS keys live on a regional service with no enclosing object."
  value       = one(oci_kms_vault.this[*].id)
}

output "kms_vault_type" {
  description = "DEFAULT or VIRTUAL_PRIVATE. Surfaced because it is NOT updatable in place and because cross-region replication requires VIRTUAL_PRIVATE."
  value       = local.kms_create ? local.vault_type : null
}

output "kms_vault_management_endpoint" {
  description = "Vault management endpoint. Required by any other module creating a key in this vault."
  value       = one(oci_kms_vault.this[*].management_endpoint)
}

output "kms_vault_crypto_endpoint" {
  description = "Vault crypto endpoint - where encrypt/decrypt calls go. Recon's `secrets_management.oci_kms.vault_crypto_endpoint`, and where `oci kms crypto encrypt` points to produce config ciphertext."
  value       = one(oci_kms_vault.this[*].crypto_endpoint)
}

output "kms_key_id" {
  description = "OCID of the customer-managed key, whether created here or supplied via kms.existing_key_id. Recon's `secrets_management.oci_kms.key_id`. Replaces kms_key_arn and kms_key_id together."
  value       = local.kms_key_id
}

output "kms_replica_enabled" {
  description = "Whether a cross-region vault replica was created. Replaces AWS's replica key ARN with a boolean - OCI replicates the VAULT."
  value       = local.kms_replica_create
}

# -----------------------------------------------------------------------------
# Object Storage
# -----------------------------------------------------------------------------

output "object_storage_namespace" {
  description = "The tenancy's Object Storage namespace. S3 bucket names are globally unique; OCI's are unique within this namespace, and every consuming API call needs it."
  value       = data.oci_objectstorage_namespace.this.namespace
}

output "recon_bucket_name" {
  description = "Recon bucket name. Replaces AWS s3_bucket_id/_arn - OCI addresses a bucket by (namespace, name), so there is no ARN to emit."
  value       = one(oci_objectstorage_bucket.recon[*].name)
}

output "secrets_enabled" {
  description = "Whether the Vault read grants (`read secret-bundles` + `read secrets`) were emitted."
  value       = local.secrets_enabled
}

# -----------------------------------------------------------------------------
# Dedicated database
# -----------------------------------------------------------------------------

output "database_created" {
  description = "Whether a dedicated database was provisioned by this module."
  value       = var.create_database
}

output "database_db_system_id" {
  description = "OCID of the db system. Replaces AWS db_cluster_arn, and is what a warm standby in another region points at, replacing the global_cluster_id + cluster_arn pair."
  value       = one(module.database[*].db_system_id)
}

output "database_endpoint" {
  description = "Writer endpoint FQDN - recon's `database.host`. Replaces AWS db_cluster_endpoint."
  value       = one(module.database[*].primary_endpoint_fqdn)
}

output "database_reader_endpoint" {
  description = "Reader endpoint FQDN, or null when disabled. Replaces AWS db_cluster_reader_endpoint."
  value       = one(module.database[*].reader_endpoint_fqdn)
}

output "database_port" {
  description = "Writer endpoint port - 5432, as on AWS."
  value       = one(module.database[*].primary_endpoint_port)
}

output "database_instance_ids" {
  description = "OCIDs of every node."
  value       = one(module.database[*].instance_ids)
}

output "database_instance_endpoints" {
  description = "Per-node endpoints. Replaces AWS db_instance_endpoints."
  value       = one(module.database[*].instance_endpoints)
}

output "database_nsg_id" {
  description = "OCID of the database's module-owned NSG. Replaces db_security_group_id, and is THE CONSUMED output: the security-last stack phase writes this database's ingress rules into it."
  value       = one(module.database[*].nsg_id)
}

output "database_admin_username" {
  description = "Bootstrap admin username."
  value       = one(module.database[*].admin_username)
  sensitive   = true
}

output "database_vault_secret_id" {
  description = "OCID of the externally managed or module-created administrator credential secret. Password values are not exported by this wrapper."
  value       = one(module.database[*].vault_secret_id)
  sensitive   = true
}

output "database_ca_certificate" {
  description = "PEM of the CA that signed the db system's server certificate. TLS is mandatory on OCI Database with PostgreSQL, so verify-ca/verify-full needs this mounted."
  value       = one(module.database[*].ca_certificate)
  sensitive   = true
}

output "database_name" {
  description = "Always null, deliberately: OCI creates only the default `postgres` database and provider 9.0.0 has no `oci_psql_database` resource, so `hyperswitch_recon` is a manual `psql` step."
  value       = null
}

# -----------------------------------------------------------------------------
# Placement
# -----------------------------------------------------------------------------

output "compartment_id" {
  description = "Compartment these resources live in, and the default location term of every statement emitted."
  value       = var.compartment_id
}

output "region" {
  description = "Region, echoed from the input."
  value       = var.region
}
