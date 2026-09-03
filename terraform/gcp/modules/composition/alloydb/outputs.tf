output "cluster_id" {
  description = "AlloyDB cluster ID"
  value       = local.cluster_id
}

output "cluster_type" {
  description = "PRIMARY for a standalone cluster, SECONDARY when this one replicates from another region's cluster"
  value       = local.is_secondary ? "SECONDARY" : "PRIMARY"

  # Cross-variable checks live here rather than in a variable validation block,
  # which cannot reference other variables below Terraform 1.9 (this module
  # floors at 1.5). Failing loudly beats silently dropping the config.
  precondition {
    condition     = !local.is_secondary || length(var.read_pool_instances) == 0
    error_message = "read_pool_instances cannot be used on a secondary cluster - AlloyDB does not support read pools there. Define them on the primary unit instead."
  }

  precondition {
    condition     = !local.is_secondary || var.master_password == null
    error_message = "master_password has no effect on a secondary cluster - it inherits the primary's users. Remove it from this unit."
  }

  precondition {
    condition     = !local.is_secondary || var.secret_manager == null || !var.secret_manager.create
    error_message = "secret_manager.create has no effect on a secondary cluster - there is no initial user to store a password for. The primary unit owns that secret."
  }
}

output "cluster_name" {
  description = "Fully-qualified cluster resource name"
  value       = module.alloydb.cluster_name
}

output "primary_instance_id" {
  description = "ID of the primary instance"
  value       = module.alloydb.primary_instance_id
}

output "primary_instance_ip" {
  description = "Private IP address of the primary instance - use this as the app's DB host"
  value       = module.alloydb.primary_instance_ip
}

output "read_instance_ids" {
  description = "IDs of the read pool instances, if any"
  value       = module.alloydb.read_instance_ids
}

output "read_instance_ips" {
  description = "Private IP addresses of the read pool instances, if any"
  value       = module.alloydb.read_instance_ips
}

# Upstream only exposes read pool ids/IPs as bare lists. It builds them by
# iterating a for_each map keyed on instance_id, so both lists come back in
# lexicographic instance_id order - which is what makes zipping them against
# the same sorted key list safe, and gives the live layer a pool it can look
# up by name instead of by list position.
output "read_instance_ids_by_name" {
  description = "Read pool instance IDs keyed by instance_id"
  value       = zipmap(local.read_pool_ids_sorted, module.alloydb.read_instance_ids)
}

output "read_instance_ips_by_name" {
  description = "Read pool private IP addresses keyed by instance_id - use these as read-replica DB hosts"
  value       = zipmap(local.read_pool_ids_sorted, module.alloydb.read_instance_ips)
}

output "instance_summary" {
  description = "What was actually provisioned: the primary's sizing plus each read pool's node count and sizing"
  value = {
    primary = {
      instance_id       = local.primary_instance_id
      availability_type = var.primary_instance.availability_type
      cpu_count         = var.primary_instance.cpu_count
      machine_type      = var.primary_instance.machine_type
    }
    read_pools = {
      for k, r in local.read_pool_instances : r.instance_id => {
        node_count   = r.node_count
        cpu_count    = r.cpu_count
        machine_type = r.machine_type
      }
    }
  }
}

output "master_username" {
  description = "Name of the bootstrap admin user"
  value       = var.master_username
}

output "generated_user_password" {
  description = "The master password in effect (module-generated if master_password was left unset)"
  value       = local.master_password
  sensitive   = true
}

output "kms_key_name" {
  description = "Self-link of the KMS key used for cluster encryption, if any"
  value       = local.kms_key_name
}

output "secret_manager_secret_id" {
  description = "Secret ID of the Secret Manager secret holding the generated master password, if secret_manager.create was set"
  value       = local.secret_manager_create ? google_secret_manager_secret.master_password[0].secret_id : null
  sensitive   = true
}

output "secret_manager_secret_name" {
  description = "Fully-qualified name (projects/.../secrets/...) of the Secret Manager secret, if created"
  value       = local.secret_manager_create ? google_secret_manager_secret.master_password[0].name : null
  sensitive   = true
}
