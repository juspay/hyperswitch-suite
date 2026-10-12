# Output contract. Four groups disappear with a reason (no VM fleet/ALB, no
# private-key persistence, no KMS alias, no global cluster / subnet-group).
# Added: vault_id, db_admin_secret_id, db_ca_certificate, workload_grants,
# encryption_at_rest.

# Key custody
output "vault_id" {
  description = "OCID of the card vault's dedicated OCI Vault. A key lives inside a vault on OCI. This is what a caller passes to any other module that must put a secret in the locker's custody boundary."
  value       = local.vault_id
}

output "vault_management_endpoint" {
  description = "Management endpoint of the vault. Required by oci_kms_key, which binds to a vault by endpoint rather than by id - pass this alongside vault_id when reusing this vault from another module."
  value       = local.management_endpoint
}

output "kms_key_id" {
  description = "OCID of the card vault's key. Replaces AWS's kms_key_arn and kms_key_id - one OCID does the work of both. HSM-protected by default. NOTE: this key encrypts this module's Vault SECRETS, not the database's storage; see encryption_at_rest."
  value       = local.key_id
}

output "kms_key_ids" {
  description = "This module's key plus any additional keys passed through kms_key.additional_key_ids. The AWS module's kms_key_arns, OCID-shaped."
  value       = local.key_ids
}

output "vault_replica_region" {
  description = "Region this vault is replicated into, or null. The AWS module's kms.multi_region / create_replica pair collapses to this: OCI replicates the whole VAULT, not one key."
  value       = try(oci_kms_vault_replication.locker[0].replica_region, null)
}

# Database
output "db_system_id" {
  description = "OCID of the card vault's dedicated db system. Replaces AWS's db_cluster_arn and db_cluster_identifier, and is what a passive-region locker's warm standby points at - the replacement for the cross-region db_global_cluster_id + db_cluster_arn pair the AWS passive root reads."
  value       = try(oci_psql_db_system.locker[0].id, null)
}

output "db_system_display_name" {
  description = "Display name of the db system. The db_cluster_identifier replacement, and the consumed one: oci_monitoring_alarm selects on resourceName in namespace oci_postgresql."
  value       = try(oci_psql_db_system.locker[0].display_name, null)
}

output "db_endpoint_fqdn" {
  description = "Writer endpoint FQDN. Replaces AWS's db_cluster_endpoint. This is what the card-vault application's connection string points at."
  value       = try(local.primary_endpoint.fqdn, null)
}

output "db_endpoint_ip" {
  description = "Writer endpoint private IP."
  value       = try(local.primary_endpoint.ip_address, null)
}

output "db_endpoint_port" {
  description = "Writer endpoint port. Replaces the port half of AWS's database_config.port."
  value       = try(local.primary_endpoint.port, null)
}

output "db_reader_endpoint_fqdn" {
  description = "Reader endpoint FQDN, or null when is_reader_endpoint_enabled is false. Replaces AWS's db_cluster_reader_endpoint. Unlike Aurora's purely DNS-based reader it is capped at 8 Gbps aggregate; db_instance_endpoints is the client-side balancing escape hatch."
  value       = try(local.reader_endpoint.fqdn, null)
}

output "db_instance_endpoints" {
  description = "Per-instance endpoints. Replaces AWS's db_instance_endpoints and db_cluster_instance_ids."
  value       = try(local.connection.instance_endpoints, [])
}

output "db_ca_certificate" {
  description = "PEM CA certificate for the db system. On OCI TLS is mandatory and cannot be disabled, so every card-vault connection string needs sslmode=require at minimum and this PEM to use verify-ca or verify-full. Distribute it before first apply; discovered later this looks like a network outage."
  value       = try(local.connection.ca_certificate, null)
  sensitive   = false
}

output "db_admin_username" {
  description = "Admin username on the card vault's database. Replaces AWS's database_config.master_username."
  value       = var.create_database ? var.database_config.admin_username : null
}

output "db_admin_secret_id" {
  description = "OCID of the Vault secret holding the admin password. THIS IS THE ONLY WAY TO OBTAIN THE PASSWORD - OCI Vault generates the value server-side and it is never a Terraform value, so there is deliberately no db_admin_password output and no plaintext in state. Read it with `read secret-bundles` (see workload_grants) or the OCI console."
  value       = local.db_secret_id
}

output "db_admin_secret_version" {
  description = "Current version number of that secret. oci_psql_db_system pins a version, so a rotation is a two-step: new version, then re-apply."
  value       = local.db_secret_version
}

output "db_system_role" {
  description = "PRIMARY or STANDBY as reported by the service. Replaces AWS's is_primary_cluster / is_secondary_cluster booleans."
  value       = try(oci_psql_db_system.locker[0].system_role, null)
}

output "db_configuration_id" {
  description = "OCID of the engine configuration, or null when no overrides are set. Replaces AWS's custom_parameter_group outputs."
  value       = local.db_configuration_id
}

# Network
output "nsg_id" {
  description = "OCID of the module-owned, EMPTY network security group on the card vault's database. Replaces AWS's db_security_group_id, and is the contract composition/security-rules consumes to write this database's ingress rules in the last stack phase. Convention: `nsg_id` singular because this module owns exactly one."
  value       = try(oci_core_network_security_group.locker_database[0].id, null)
}

output "subnet_id" {
  description = "Subnet the database was placed in. Singular, because OCI's db system takes one subnet OCID and has no subnet group - AWS's subnet_ids list has no counterpart."
  value       = var.subnet_id
}

# Logging
output "log_group_id" {
  description = "OCID of the card vault's log group. Replaces AWS's aws_cloudwatch_log_group.locker."
  value       = try(oci_logging_log_group.locker[0].id, null)
}

output "log_id" {
  description = "OCID of the database engine log."
  value       = try(oci_logging_log.database[0].id, null)
}

# Identity
output "workload_grants" {
  description = <<-EOT
    The card-vault pod's OKE workload-identity grants, in exactly the shape
    application-resources/oke-workload-identity's `workload_grants` variable
    takes. Wire this into that unit; do NOT create a policy object for the
    locker.

    This is the replacement for the AWS module's IAM role, and it is
    deliberately not role-shaped. There is no role object on OCI and no
    service-account annotation: the policy statement names the (cluster,
    namespace, service account) tuple, and the pod side is `serviceAccountName`
    plus `automountServiceAccountToken: true` and nothing else. Offering an id
    here that looked like a role ARN would invite someone to annotate a service
    account with it and produce an identity that works by accident.

    Review the list, do not skim it - each entry becomes a statement whose
    `where` conditions ARE the security boundary, and an omission fails OPEN.
  EOT
  value       = local.workload_grants
}

output "k8s_service_account" {
  description = "The (namespace, service_account) pair the grants above authorise. Audit surface; confirm it against the deployed hyperswitch-card-vault chart."
  value = {
    namespace       = var.k8s_namespace
    service_account = var.k8s_service_account_name
  }
}

# Disclosure
output "encryption_at_rest" {
  description = <<-EOT
    Deliberate, machine-readable disclosure of the port's largest security
    delta, so a plan review cannot miss it and a consumer cannot assume
    otherwise. Replaces AWS's storage_encrypted / db_kms_key_arn outputs, which
    would be actively misleading if emitted here.

    The card vault's database IS encrypted at rest, under an Oracle-managed
    key. It is NOT encrypted under this module's key, and it cannot be: neither
    oci_psql_db_system nor oci_psql_configuration exposes a customer-managed-key
    argument in provider 9.0.0, and oci/modules/database.md section 4.9
    confirms the same absence in the OCI console's create flow. The AWS locker
    creates its own KMS key and encrypts its dedicated Aurora cluster with it.

    Needs an explicit sign-off from
    whoever owns PCI-DSS scope, separate from the shared database's.
  EOT
  value = {
    database_encrypted       = var.create_database
    database_key_custody     = "oracle-managed"
    database_customer_key_id = null
    secrets_key_custody      = local.key_id != null ? "customer-managed" : "none"
    secrets_customer_key_id  = local.key_id
  }
}
