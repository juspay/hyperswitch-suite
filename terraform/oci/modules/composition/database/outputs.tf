# Outputs. The AWS module's 47 outputs collapse to the set below - mostly
# removal of things OCI does not have (no global object, no subnet-group, no
# kms module, no per-app database, no per-instance AZ).

output "db_system_id" {
  description = "OCID of the db system. Replaces AWS cluster_id, cluster_arn and cluster_resource_id - one OCID does the work of three identifiers. This is also what a warm standby in another region points at, replacing the global_cluster_id + cluster_arn pair the AWS passive root reads cross-region."
  value       = oci_psql_db_system.this.id
}

output "db_system_display_name" {
  description = "Display name of the db system. The cluster_identifier replacement, and the CONSUMED output: oci_monitoring_alarm selects on resourceName in namespace oci_postgresql, so this is the direct substitution for the cloudwatch-alarms DBClusterIdentifier dimension."
  value       = oci_psql_db_system.this.display_name
}

output "system_role" {
  description = "PRIMARY or STANDBY, as reported by the service. Replaces AWS's is_primary_cluster / is_secondary_cluster booleans with the provider's own discriminator."
  value       = oci_psql_db_system.this.system_role

  # Cross-variable guards. These live on an output rather than in variable
  # validation blocks because those cannot reference other variables below
  # Terraform 1.9; failing loudly at plan time beats failing mid-apply on a
  # payments database.

  precondition {
    condition     = var.enable_warm_standby == (var.primary_db_system_id != null)
    error_message = "enable_warm_standby and primary_db_system_id must be set together. Warm standby is OFF by default and that default is a decision (300 s RPO floor, manual-only failover, second full db system) - review before turning it on."
  }

  precondition {
    condition     = !var.enable_warm_standby || (var.source_backup_id == null && var.source_pitr == null)
    error_message = "Warm standby and restore are mutually exclusive on the same db system: 'Restore Database system isn't supported for Replication with Warm Standby database systems (primary & warm standby)'. Create from backup or PITR FIRST, then establish the standby relationship; to restore a replicated pair, break replication, restore, re-establish."
  }

  precondition {
    condition     = var.source_backup_id == null || var.source_pitr == null
    error_message = "source_backup_id and source_pitr are mutually exclusive - a db system has exactly one source."
  }

  precondition {
    condition     = !var.enable_warm_standby || contains(["14", "15", "16", "17"], var.db_version)
    error_message = "Replication with Warm Standby requires PostgreSQL 14 or higher on BOTH the primary and the standby."
  }

  precondition {
    condition     = !var.is_regionally_durable || var.availability_domain == null
    error_message = "availability_domain cannot be set when is_regionally_durable = true - the provider forbids the pair: 'If isRegionallyDurable is set to true, availabilityDomain should not be specified.' Leave it null, or set is_regionally_durable = false."
  }

  # This is the load-bearing REGION-property guard (the pair above is a provider
  # schema rule and was always enforced). A wrong is_regionally_durable value
  # sails past four clean plans and fails 400 on the real create call, so this
  # checks the value against a real availability-domain listing at plan time.
  # Threshold is 3, not 2, because no OCI region has exactly 2 ADs - a region
  # has 1 or 3.
  precondition {
    condition     = !var.is_regionally_durable || local.availability_domain_count >= 3
    error_message = "is_regionally_durable = true requires a 3-AD region, and this compartment's region reports ${local.availability_domain_count} availability domain(s): ${join(", ", local.availability_domain_names)}. The API rejects the create with 'This feature is only supported in 3 AD regions. Please set the parameter as false and specify availabilityDomain.' Set is_regionally_durable = false; the module then pins storage to the single AD automatically. NOTE this is not a downgrade - with one AD, regional and AD-local placement put the nodes in the same three fault domains of the same AD either way (section 4.3)."
  }

  # availability_domain is mandatory when is_regionally_durable = false. The
  # caller is NOT required to supply it: local.availability_domain resolves
  # index 0 of the real listing (AD names carry a tenancy-scoped opaque prefix,
  # so they are unsafe to hardcode). This fires only if the listing came back
  # empty, meaning the credential cannot see the compartment.
  precondition {
    condition     = var.is_regionally_durable || local.availability_domain != null
    error_message = "availability_domain is required when is_regionally_durable = false, and data.oci_identity_availability_domains returned no availability domains for compartment ${var.compartment_id}. Either the compartment OCID is wrong or the credential cannot list availability domains; pass var.availability_domain explicitly to bypass the lookup."
  }

  precondition {
    condition     = !var.create_nsg || var.vcn_id != null
    error_message = "vcn_id is required when create_nsg = true - oci_core_network_security_group is created inside a VCN."
  }

  precondition {
    condition     = var.vault_secret == null || !var.vault_secret.create || (var.vault_secret.vault_id != null && var.vault_secret.key_id != null)
    error_message = "vault_secret.create requires both vault_id and key_id. OCI Vault secrets are encrypted with a customer-managed key - which, note, is the only place in this module where customer key custody is possible at all."
  }

  precondition {
    condition     = !var.enable_warm_standby || var.admin_password == null
    error_message = "admin_password has no effect on a warm standby - 'Users and roles are replicated from the primary ... The warm standby database can't have dedicated users or roles.' Remove it from this unit; the primary owns the credential."
  }

  precondition {
    condition     = !contains(var.backup_copy_regions, var.region)
    error_message = "A backup cannot be copied into the region it was created in. Remove this region from backup_copy_regions."
  }

  precondition {
    condition     = var.prevent_destroy
    error_message = "prevent_destroy = false does not weaken this module's guard and is rejected deliberately. oci_psql_db_system has NO deletion_protection argument in provider 9.0.0, and Terraform forbids a variable in lifecycle.prevent_destroy, so the lifecycle block in main.tf is hardcoded true. To tear this db system down on purpose: (1) confirm a retained backup exists, (2) comment out the lifecycle block in main.tf on a branch and apply, (3) destroy. See section 4.12."
  }
}

output "is_standby" {
  description = "True when this db system is a warm standby of another region's. Replaces AWS is_secondary_cluster and replication_source_identifier."
  value       = local.is_standby
}

output "primary_db_system_id" {
  description = "OCID of the primary this system replicates from, echoed back. Null on a standalone or primary system."
  value       = var.primary_db_system_id
}

output "replication_config" {
  description = "Configured cross-region DR posture. The manual-failover runbook has to be able to read the RPO that is actually in force, because there is no automatic failover to fall back on. rpo_in_seconds is the ENFORCEMENT THRESHOLD, not a measured lag; no steady-state lag figure is published for warm standby."
  value = {
    enabled         = local.is_standby
    is_rpo_enforced = local.is_standby ? var.is_rpo_enforced : null
    rpo_in_seconds  = local.is_standby ? var.rpo_in_seconds : null
  }
}

output "instance_ids" {
  description = "OCIDs of every node. Replaces AWS cluster_members, cluster_instance_ids and cluster_instance_arns."
  value       = [for i in oci_psql_db_system.this.instances : i.id]
}

output "instance_availability_domains" {
  description = "Availability domain of each node. Replaces cluster_instance_availability_zones. In a single-AD region every entry is the SAME AD - the nodes are separated by fault domain, not by AD (section 4.3). Do not read a spread here that is not there."
  value       = [for i in oci_psql_db_system.this.instances : i.availability_domain]
}

output "instance_endpoints" {
  description = "Per-node endpoints, keyed by db instance OCID. Replaces cluster_instance_endpoints, and doubles as the escape hatch for the reader endpoint's 8 Gbps aggregate ceiling (section 4.2): a heavy read consumer can balance client-side across these instead."
  value = {
    for e in local.connection.instance_endpoints : e.db_instance_id => {
      fqdn       = try(e.endpoint[0].fqdn, null)
      ip_address = try(e.endpoint[0].ip_address, null)
      port       = try(e.endpoint[0].port, null)
    }
  }
}

output "primary_endpoint_fqdn" {
  description = "Writer endpoint FQDN - the stable name a failover promotes a replica behind. Replaces AWS `endpoint`. Note that no unit reads this: applications get their DB host through external-secrets, on OCI as on AWS."
  value       = try(local.primary_endpoint.fqdn, null)
}

output "primary_endpoint_ip" {
  description = "Writer endpoint private IP."
  value       = try(local.primary_endpoint.ip_address, null)
}

output "primary_endpoint_port" {
  description = "Writer endpoint port - 5432, as on AWS. Replaces AWS `port`. AWS's hosted_zone_id has no counterpart: OCI publishes a service-managed FQDN and there is no customer zone to alias."
  value       = try(local.primary_endpoint.port, null)
}

output "reader_endpoint_fqdn" {
  description = "Reader endpoint FQDN, or null when is_reader_endpoint_enabled = false. Replaces AWS reader_endpoint. Capped at 8 Gbps aggregate, unlike Aurora's purely DNS-based reader endpoint - see instance_endpoints."
  value       = try(local.reader_endpoint.fqdn, null)
}

output "reader_endpoint_ip" {
  description = "Reader endpoint private IP, or null when the reader endpoint is disabled."
  value       = try(local.reader_endpoint.ip_address, null)
}

output "ca_certificate" {
  description = "PEM of the CA that signed the db system's server certificate. Replaces AWS ca_certificate_identifier / ca_certificate_valid_till with a different SHAPE - OCI hands back the certificate itself, not an identifier. NEEDED BY EVERY APPLICATION, because TLS is mandatory on OCI and cannot be turned off: mount this through external-secrets for sslmode=verify-ca or verify-full. sslmode=require works without it; sslmode=disable fails outright (section 4.11)."
  value       = local.connection.ca_certificate
  sensitive   = true
}

output "nsg_id" {
  description = "OCID of the module-owned network security group. Replaces AWS security_group_id / security_group_arn / security_group_name, and is THE CONSUMED output: the security-rules equivalent, running last in the stack, writes this database's ingress rules into it."
  value       = var.create_nsg ? oci_core_network_security_group.this[0].id : null
}

output "nsg_ids" {
  description = "Every NSG attached to the db system - the module-owned one plus any passed in."
  value       = local.nsg_ids
}

output "configuration_id" {
  description = "OCID of the engine configuration in effect, or null when the service default applies. Replaces custom_parameter_group_name / _arn / _id."
  value       = local.configuration_id
}

output "db_version_actual" {
  description = "Engine version as reported by the service. Replaces AWS engine_version_actual; AWS's `engine` output has no counterpart because OCI has exactly one managed PostgreSQL offering and one mode, so it would be a constant."
  value       = oci_psql_db_system.this.db_version
}

output "admin_username" {
  description = "Bootstrap admin username. Replaces master_username. On a warm standby this is inherited from the primary, not set here."
  value       = var.admin_username
  sensitive   = true
}

output "admin_password" {
  description = "The admin password in effect, module-generated when admin_password was left unset. Null on a warm standby."
  value       = local.admin_password
  sensitive   = true
}

output "vault_secret_id" {
  description = "OCID of the OCI Vault secret holding the admin password, when vault_secret.create was set. Replaces AWS master_user_secret, with a different mechanism: the caller owns the secret and nothing rotates it (section 4.10)."
  value       = local.vault_secret_create ? oci_vault_secret.admin_password[0].id : null
  sensitive   = true
}

output "vault_secret_name" {
  description = "Name of the OCI Vault secret holding the admin password, if created."
  value       = local.vault_secret_name
  sensitive   = true
}

output "backup_policy" {
  description = "Scheduled-backup policy in effect. Half of what AWS expressed as the single backup_retention_period number - see pitr_policy for the other half. backup_start is reported in the wire format, \"HH:MM\" UTC, and is always on the hour: the module schedules at hour granularity, so AWS's minute-precision window \"00:51-01:21\" becomes 00:00 (C12)."
  value = {
    kind                = var.backup_kind
    backup_start        = format("%s:00", var.backup_start_hour)
    retention_days      = var.backup_retention_days
    copy_to_regions     = var.backup_copy_regions
    days_of_the_week    = var.backup_days_of_the_week
    days_of_the_month   = var.backup_days_of_the_month
    survives_deletion   = true
    on_demand_backup_id = var.on_demand_backup != null ? oci_psql_backup.on_demand[0].id : null
  }
}

output "pitr_policy" {
  description = "Point-in-time recovery policy. The other half of AWS's backup_retention_period, and an INDEPENDENT policy on OCI - a database with backup_policy set and pitr_policy unset has no PITR at all. In-region only; unavailable entirely while warm standby is enabled."
  value = {
    kind         = "STANDARD"
    restore_days = var.pitr_restore_days
    available    = !local.is_standby
  }
}

output "maintenance_window_start" {
  description = "Maintenance window start, or null for the service default. Replaces preferred_maintenance_window. AWS's engine_lifecycle_support has no counterpart - OCI has no extended-support lifecycle, so an engine past end-of-life cannot be kept running (section 4.13)."
  value       = oci_psql_db_system.this.management_policy[0].maintenance_window_start
}

output "log_group_id" {
  description = "OCID of the OCI Logging log group, if service logs are enabled. New output - AWS needed none because log export was an argument on the cluster."
  value       = var.enable_service_logs ? oci_logging_log_group.this[0].id : null
}

output "log_id" {
  description = "OCID of the engine log, if service logs are enabled. Consumers that ship logs onward need this."
  value       = var.enable_service_logs ? oci_logging_log.database[0].id : null
}

output "freeform_tags" {
  description = "Freeform tags actually applied. The tags_all replacement."
  value       = oci_psql_db_system.this.freeform_tags
}

output "encryption_at_rest" {
  description = <<-EOT
    Encryption posture. Data IS encrypted at rest, but only with Oracle-managed
    keys. Provider 9.0.0's oci_psql_db_system has NO customer-managed-key
    argument, and the console create flow has no encryption-key section either;
    the only Vault reference there is the admin password. There is no toggle, so
    this module deliberately offers none: an empty CMEK variable would imply a
    capability that does not exist.

    Consequence for a PCI-scope payments database: the tenancy cannot
    demonstrate customer-held key custody for data at rest. That is an audit
    finding to be accepted in writing by the security owner, not a Terraform
    problem. What remains available: pgcrypto for application-level encryption
    (available by default), and a customer-managed key on the OCI Vault secret
    holding the admin credential.
  EOT
  value = {
    enabled                = true
    key_management         = "ORACLE_MANAGED"
    customer_managed_key   = false
    cmek_supported         = false
    credential_key_id      = try(var.vault_secret.key_id, null)
    deletion_protection    = false
    deletion_protection_by = "terraform lifecycle.prevent_destroy only - no service-side control exists"
  }
}
