locals {
  display_name = coalesce(var.display_name, "${var.environment}-${var.project_name}-db")
}

# ============================================================================
# OCI Database with PostgreSQL DB System
# Equivalent of the AWS `database` composition module (Aurora PostgreSQL
# cluster via aws_rds_cluster / aws_rds_cluster_instance).
# No verified registry module exists for this resource - raw oci provider.
# ============================================================================
resource "oci_psql_db_system" "this" {
  compartment_id = var.compartment_id
  display_name   = local.display_name
  db_version     = var.db_version
  shape          = var.shape
  config_id      = var.config_id

  instance_ocpu_count         = var.instance_ocpu_count
  instance_memory_size_in_gbs = var.instance_memory_size_in_gbs
  instance_count              = var.instance_count

  network_details {
    subnet_id = var.subnet_id
    nsg_ids   = var.nsg_ids
  }

  storage_details {
    is_regionally_durable = var.storage_is_regionally_durable
    system_type           = var.storage_system_type
  }

  credentials {
    username = var.admin_username
    password_details {
      password_type  = "VAULT_SECRET"
      secret_id      = var.admin_password_secret_id
      secret_version = var.admin_password_secret_version
    }
  }

  management_policy {
    backup_policy {
      kind           = var.backup_policy_kind
      backup_start   = var.backup_policy_kind != "DISABLED" ? var.backup_start_hour : null
      retention_days = var.backup_retention_days
    }
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}
