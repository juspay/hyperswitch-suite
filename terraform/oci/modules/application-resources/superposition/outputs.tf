# =============================================================================
# Output contract - 29 AWS outputs become the set below.
# =============================================================================
# DELETED WITH NO REPLACEMENT:
#   role_arn, role_name, role_id, role_unique_id  - no role exists, and no
#     service-account annotation exists to consume one. Offering an OCID as
#     "the new role_arn" would invite someone to annotate a service account
#     with it (identity-model.md section 6.4).
#   attached_policy_arns / inline_policy_names    - nothing is attachable.
#   oidc_provider_urls                            - no OIDC registration.
#   db_global_cluster_id / _arn / _identifier / db_global_writer_endpoint
#     - no global-cluster object exists on OCI (database.md section 4.4). The
#       passive side reads `database_db_system_id` instead.
#   database_kms_key_arn / _id / _aliases         - oci_psql_db_system has no
#     customer-managed-key argument at all in provider 9.0.0 (database.md
#     section 4.9, PARTIAL). Emitting nulls named after a capability that does
#     not exist would let a consumer plan around it.
# =============================================================================

# -----------------------------------------------------------------------------
# THE IDENTITY CONTRACT
# -----------------------------------------------------------------------------

output "policy_statements" {
  description = <<-EOT
    This module's contribution to the ONE shared, environment-scoped
    `oci_identity_policy` owned by the `oke-workload-identity` unit. Rendered,
    normalised and sorted.

    THIS MODULE CREATES NO POLICY OBJECT (`oci_identity_policy.name` is
    tenancy-unique and non-updatable; per-app objects are unbuildable at this
    footprint - identity-model.md section 3.7). Hand this list to
    `oke-workload-identity`; do not wrap it in a policy resource in the caller.

    Expect ONE statement per cluster per service account - the `use keys` grant
    on hyperswitch's key - plus anything in `extra_statements`. If this list is
    empty, `kms_key_id` was not supplied and this workload has no cloud grants
    at all, which is a legitimate configuration and is why it is not an error.
  EOT
  value       = local.policy_statements
}

output "statement_count" {
  description = "Number of statements contributed, against the shared policy object's hard 50-statement ceiling."
  value       = length(local.policy_statements)
}

output "authorized_workloads" {
  description = "Every (cluster_id, namespace, service_account) tuple these statements authorise. Replaces the AWS module's `cluster_service_accounts` echo; for audit, not for consumption."
  value       = local.authorized_workloads
}

output "kms_key_id" {
  description = "The KMS key OCID this workload was granted `use keys` on - hyperswitch's key, echoed back so a reviewer can see the cross-module edge without reading the statements. Null when no grant was emitted."
  value       = var.kms_key_id
}

# -----------------------------------------------------------------------------
# Nested database - a strict subset of composition/database's own outputs,
# re-exported rather than redefined. 16 AWS `database_*` outputs collapse here.
# -----------------------------------------------------------------------------

output "database_created" {
  description = "Whether a dedicated database was provisioned by this module."
  value       = var.create_database
}

output "database_db_system_id" {
  description = "OCID of the db system. Replaces AWS database_cluster_id AND database_cluster_arn - one OCID does the work of both - and is ALSO what a warm standby in another region points at, replacing the global_cluster_id + cluster_arn pair the AWS passive root reads."
  value       = one(module.database[*].db_system_id)
}

output "database_endpoint" {
  description = "Writer endpoint FQDN. Replaces AWS database_endpoint. AWS's hosted_zone_id has no counterpart: OCI publishes a service-managed FQDN with no customer zone to alias."
  value       = one(module.database[*].primary_endpoint_fqdn)
}

output "database_reader_endpoint" {
  description = "Reader endpoint FQDN, or null when disabled. Replaces AWS database_reader_endpoint. Capped at 8 Gbps aggregate, unlike Aurora's purely DNS-based reader endpoint."
  value       = one(module.database[*].reader_endpoint_fqdn)
}

output "database_port" {
  description = "Writer endpoint port - 5432, as on AWS."
  value       = one(module.database[*].primary_endpoint_port)
}

output "database_instance_ids" {
  description = "OCIDs of every node. Replaces database_cluster_instance_ids."
  value       = one(module.database[*].instance_ids)
}

output "database_instance_endpoints" {
  description = "Per-node endpoints. Replaces database_cluster_instance_endpoints, and doubles as the client-side balancing escape hatch for the reader endpoint's 8 Gbps ceiling."
  value       = one(module.database[*].instance_endpoints)
}

output "database_nsg_id" {
  description = "OCID of the database's module-owned NSG. Replaces database_security_group_id, and is THE CONSUMED output: the security-last stack phase writes this database's ingress rules into it."
  value       = one(module.database[*].nsg_id)
}

output "database_admin_username" {
  description = "Bootstrap admin username. Replaces database_master_username."
  value       = one(module.database[*].admin_username)
  sensitive   = true
}

output "database_vault_secret_id" {
  description = "OCID of the Vault secret holding the generated admin password, when database_config.vault_secret.create was set. Replaces AWS master_user_secret with a different mechanism - the caller owns the secret and nothing rotates it (database.md section 4.10)."
  value       = one(module.database[*].vault_secret_id)
  sensitive   = true
}

output "database_ca_certificate" {
  description = "PEM of the CA that signed the db system's server certificate. NEEDED BY THE APPLICATION: TLS is mandatory on OCI Database with PostgreSQL and cannot be turned off, so every connection string needs sslmode=require at minimum, and verify-ca/verify-full needs this mounted. AWS's ca_certificate_identifier was an identifier; this is the certificate itself."
  value       = one(module.database[*].ca_certificate)
  sensitive   = true
}

output "database_name" {
  description = <<-EOT
    Always null, and deliberately so rather than omitted.

    OCI creates only the default `postgres` database, and provider 9.0.0 has no
    `oci_psql_database` resource - so a per-app database (`superposition_v2`)
    cannot be declared in Terraform at all and remains a manual `psql` step.
    GCP's AlloyDB port hit the identical wall. database.md open question 9.4.

    Emitted as an explicit null so a consumer reading this output sees the gap
    rather than assuming the value simply was not wired through.
  EOT
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
