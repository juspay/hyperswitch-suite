# ============================================================================
# AlloyDB (GCP's Aurora-PostgreSQL equivalent - production-grade alternative
# to composition/cloud-sql). Wraps the Google-maintained registry module
# rather than hand-rolling the dynamic network_config/psc_config blocks the
# native google_alloydb_cluster resource needs (a known provider bug exists
# around those - hashicorp/terraform-provider-google#18481).
#
# Reuses composition/vpc-network's existing Private Service Access setup -
# no separate PSC/network module needed. network_id and allocated_ip_range
# both come from that module's outputs (network_id / private_service_access_range_name).
#
# Usage:
#   module "alloydb" {
#     source = "../../modules/composition/alloydb"
#
#     project_id          = "hyperswitch-dev"
#     environment         = "dev"
#     region              = "asia-south1"
#     network_id          = module.vpc_network.network_id
#     allocated_ip_range  = module.vpc_network.private_service_access_range_name
#
#     depends_on = [module.vpc_network] # for Private Service Access
#   }
# ============================================================================

resource "random_password" "master" {
  count = local.generate_password ? 1 : 0

  length      = 32
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1

  keepers = {
    name = local.cluster_id
  }
}

module "alloydb" {
  source  = "GoogleCloudPlatform/alloy-db/google"
  version = "~> 8.0"

  project_id = var.project_id
  cluster_id = local.cluster_id
  location   = var.region

  cluster_type         = "PRIMARY"
  database_version     = var.database_version
  cluster_labels       = local.common_labels
  cluster_display_name = local.cluster_id

  network_self_link  = var.network_id
  allocated_ip_range = var.allocated_ip_range

  cluster_initial_user = {
    user     = var.master_username
    password = local.master_password
  }

  cluster_encryption_key_name = local.kms_key_name

  deletion_protection = var.deletion_protection

  continuous_backup_enable               = var.continuous_backup_enabled
  continuous_backup_recovery_window_days = var.continuous_backup_recovery_window_days

  automated_backup_policy = var.automated_backup_enabled ? {
    enabled  = true
    location = var.region
    weekly_schedule = {
      days_of_week = ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"]
      start_times  = [format("%02d:00:00:0", var.automated_backup_start_hour)]
    }
    quantity_based_retention_count = var.automated_backup_retention_count
    labels                         = local.common_labels
  } : null

  primary_instance = {
    instance_id       = "${local.cluster_id}-primary"
    availability_type = var.primary_availability_type
    machine_config = {
      cpu_count    = var.primary_machine_type == null ? var.primary_cpu_count : null
      machine_type = var.primary_machine_type
    }
  }

  read_pool_instance = [
    for r in var.read_pool_instances : {
      instance_id = r.instance_id
      node_count  = r.node_count
      machine_config = {
        cpu_count = r.cpu_count
      }
    }
  ]
}
