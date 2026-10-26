# Identity

output "service_account_email" {
  description = "Email of the locker's Google service account - the identity the GKE workload assumes via Workload Identity"
  value       = module.workload_identity.gcp_service_account_email

  # create_database = true needs a network to attach the cluster to, and
  # AlloyDB takes the Private Service Access range by NAME. Both are typed
  # optional so create_database = false callers can omit them, which means
  # nothing else would catch them being missing until the nested module
  # failed with a much less obvious error. Terraform 1.5 cannot cross-
  # reference variables inside a validation block, so the check lives here.
  precondition {
    condition     = !var.create_database || var.database_config.network_id != null
    error_message = "database_config.network_id is required when create_database = true."
  }

  precondition {
    condition     = !var.create_database || var.database_config.allocated_ip_range != null
    error_message = "database_config.allocated_ip_range is required when create_database = true - AlloyDB attaches over Private Service Access and takes the reserved range by name (composition/vpc-network exposes it as private_service_access_range_name)."
  }
}

output "service_account_name" {
  description = "Fully qualified name of the locker's Google service account"
  value       = module.workload_identity.gcp_service_account_name
}

output "k8s_service_account_name" {
  description = "Bound Kubernetes service account name - set the locker's pod spec serviceAccountName to this"
  value       = module.workload_identity.k8s_service_account_name
}

output "k8s_service_account_namespace" {
  description = "Namespace of the bound Kubernetes service account"
  value       = module.workload_identity.k8s_service_account_namespace
}

output "granted_project_roles" {
  description = "Project-level IAM roles granted to the locker's service account"
  value       = local.project_roles
}

# Database

output "database_cluster_name" {
  description = "Fully-qualified resource name of the vault's AlloyDB cluster, if created"
  value       = var.create_database ? module.database[0].cluster_name : null
}

output "database_cluster_id" {
  description = "AlloyDB cluster ID of the vault's cluster, if created"
  value       = var.create_database ? module.database[0].cluster_id : null
}

output "database_host" {
  description = "Private IP of the vault cluster's primary instance - the host the locker pod connects to"
  value       = var.create_database ? module.database[0].primary_instance_ip : null
}

output "database_port" {
  description = "PostgreSQL port for the vault cluster. Fixed at 5432; exposed so callers templating a connection string do not hardcode it"
  value       = 5432
}

output "master_username" {
  description = "Bootstrap admin username on the vault's cluster"
  value       = var.create_database ? module.database[0].master_username : null
}

output "master_password_secret_id" {
  description = "Secret ID of the Secret Manager secret holding the generated master password, if one was created. This is what the locker's service account is granted accessor on"
  value       = local.grant_master_password_access ? module.database[0].secret_manager_secret_id : null
  sensitive   = true
}

output "master_password_secret_name" {
  description = "Fully-qualified name (projects/.../secrets/...) of the master password secret, if created - the reference to put in the locker's ExternalSecret or CSI SecretProviderClass"
  value       = local.grant_master_password_access ? module.database[0].secret_manager_secret_name : null
  sensitive   = true
}

# CMEK

output "kms_key_name" {
  description = "Self-link of the KMS key encrypting the vault's cluster, whether created here or supplied via encryption_key_name"
  value       = local.kms_key_name
}

output "kms_keyring_name" {
  description = "Name of the created keyring, if this module created one"
  value       = var.create_kms_key && var.encryption_key_name == null ? module.kms[0].keyring_name : null
}
