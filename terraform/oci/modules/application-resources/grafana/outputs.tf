# Output contract

output "policy_statements" {
  description = <<-EOT
    This module's contribution to the ONE shared, environment-scoped
    `oci_identity_policy` owned by the `oke-workload-identity` unit. Rendered,
    normalised and sorted.

    THIS MODULE CREATES NO POLICY OBJECT (identity-model.md section 3.7). Hand
    this list to `oke-workload-identity`.

    Expect exactly THREE statements per cluster: `read metrics`,
    `read log-content`, `read log-groups`. If you see `use metrics` or
    `use log-content` here, something is wrong - those are the PUBLISH verbs
    `otel-collector` needs, not the query verbs a dashboard needs.

    THE DATABASE ADDS ZERO STATEMENTS. OCI Database with PostgreSQL has no
    IAM-principal-to-database-user auth path; Grafana connects with a username
    and password over mandatory TLS.
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

output "datasource_uses_static_credential" {
  description = <<-EOT
    TRUE means Grafana's OCI Monitoring/Logging datasources are authenticating
    with a static User Principal API key rather than workload identity.

    Surfaced as an output, and therefore in the plan, because it is an accepted
    regression against identity-model.md section 3.1 and must not be taken
    quietly. It flips only when `datasource_api_key_vault_secret_id` is set,
    i.e. when check sheet section 9 Q1 has resolved against the plugins
    supporting a workload-identity SDK path.

    False does NOT mean the datasources work - it means no static credential was
    wired. If Q1 resolves against workload identity and this stays false,
    Grafana is blind to everything OCI Monitoring and OCI Logging carry, which
    is a real user-visible gap in a monitoring platform's view of its own cloud.
  EOT
  value       = local.datasource_uses_static_credential
}

output "datasource_api_key_vault_secret_id" {
  description = "Echo of the Vault secret OCID holding the datasource API-key fallback, for an ExternalSecret to project. The OCID only - this module never reads, stores or emits a credential value."
  value       = var.datasource_api_key_vault_secret_id
}

output "metrics_read_enabled" {
  description = "Whether the `read metrics` grant was emitted."
  value       = var.metrics_read_enabled
}

output "logs_read_enabled" {
  description = "Whether the `read log-content` + `read log-groups` grants were emitted."
  value       = var.logs_read_enabled
}

output "database_created" {
  description = "Whether a dedicated database was provisioned by this module."
  value       = var.create_database
}

output "database_db_system_id" {
  description = "OCID of the db system. Replaces database_cluster_id AND database_cluster_arn - one OCID does the work of both."
  value       = one(module.database[*].db_system_id)
}

output "database_endpoint" {
  description = "Writer endpoint FQDN. What GF_DATABASE_HOST points at."
  value       = one(module.database[*].primary_endpoint_fqdn)
}

output "database_reader_endpoint" {
  description = "Reader endpoint FQDN, or null when disabled. Capped at 8 Gbps aggregate, unlike Aurora's purely DNS-based reader endpoint."
  value       = one(module.database[*].reader_endpoint_fqdn)
}

output "database_port" {
  description = "Writer endpoint port - 5432, as on AWS."
  value       = one(module.database[*].primary_endpoint_port)
}

output "database_nsg_id" {
  description = "OCID of the database's module-owned NSG. Replaces database_security_group_id, and is consumed by the security-last stack phase, which writes the ingress rules into it."
  value       = one(module.database[*].nsg_id)
}

output "database_admin_username" {
  description = "Bootstrap admin username. Replaces database_master_username. What GF_DATABASE_USER is set to."
  value       = one(module.database[*].admin_username)
  sensitive   = true
}

output "database_vault_secret_id" {
  description = "OCID of the Vault secret holding the generated admin password, when database_config.vault_secret.create was set. Project it into the pod with external-secrets-operator rather than granting Grafana direct Vault access (check sheet section 9 Q4)."
  value       = one(module.database[*].vault_secret_id)
  sensitive   = true
}

output "database_ca_certificate" {
  description = <<-EOT
    PEM of the CA that signed the db system's server certificate.

    NEEDED BY GRAFANA, not optional metadata. TLS is mandatory on OCI Database
    with PostgreSQL and cannot be turned off, so GF_DATABASE_SSL_MODE must be
    `require` at minimum; for `verify-ca` or `verify-full` this certificate has
    to be mounted into the pod, most naturally through the same
    external-secrets-operator path already carrying the password.

    AWS emitted an IDENTIFIER (ca_certificate_identifier); OCI hands back the
    certificate itself. Different shape, not just a different name.
  EOT
  value       = one(module.database[*].ca_certificate)
  sensitive   = true
}

output "database_tls_required" {
  description = "Always true, and not configurable. Stated as a first-class output so a consumer reading this module cannot mistake AWS's TLS-optional default for what happens here (check sheet feature 5, verdict NONE)."
  value       = true
}

output "database_name" {
  description = "Always null. OCI creates only the default `postgres` database and provider 9.0.0 has no `oci_psql_database` resource, so a `grafana` database is a manual `psql` step (database.md open question 9.4). Emitted explicitly so the gap is visible rather than looking like an unwired value."
  value       = null
}

output "host_domains_map" {
  description = "DNS/ingress metadata, echoed unchanged. Feature 7, FULL - no cloud resource behind it on any cloud, and the GCP precedent has the identical output."
  value       = var.host_domains
}

output "compartment_id" {
  description = "Compartment these resources live in, and the location term of every statement emitted."
  value       = var.compartment_id
}

output "region" {
  description = "Region, echoed from the input."
  value       = var.region
}
