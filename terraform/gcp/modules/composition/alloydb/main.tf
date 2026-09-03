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
#     primary_instance = {
#       availability_type = "REGIONAL"
#       cpu_count         = 8
#       database_flags    = { "alloydb.iam_authentication" = "on" }
#     }
#
#     read_pool_instances = {
#       read-1 = { node_count = 2, cpu_count = 4 }
#     }
#
#     depends_on = [module.vpc_network] # for Private Service Access
#   }
#
# Cross-region DR: leave primary_cluster_name unset and this is a standalone
# PRIMARY. Point a second instantiation of this module - in another region,
# same VPC - at this one's `cluster_name` output and that becomes a SECONDARY:
#
#   module "alloydb_dr" {
#     source = "../../modules/composition/alloydb"
#     region = "asia-south2"
#     primary_cluster_name = module.alloydb.cluster_name
#     ...same project_id / network_id / allocated_ip_range...
#   }
#
# The PSA allocated range is a global address and the peering is per-network,
# so a second region reuses the same network_id/allocated_ip_range with no
# extra networking. A secondary inherits the primary's users (no initial user,
# no generated password, no Secret Manager entry) and cannot host read pools;
# backups are configured per-cluster and stay active on both. Promotion and
# switchover are manual gcloud operations - see README.
#
# Instance model: AlloyDB gives you exactly ONE primary per cluster, so there
# is no direct analogue of the AWS composition/database module's
# cluster_instances map of N writers/readers. Read scaling is read pools, each
# a single instance fronting node_count nodes - primary_instance plus the
# read_pool_instances map is as close as the platform gets.
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

  # Upstream derives SECONDARY from primary_cluster_name on its own; setting
  # cluster_type alongside it keeps the intent readable at this level.
  cluster_type         = local.is_secondary ? "SECONDARY" : "PRIMARY"
  primary_cluster_name = var.primary_cluster_name
  database_version     = var.database_version
  cluster_labels       = local.common_labels
  cluster_display_name = local.cluster_id

  network_self_link  = var.network_id
  allocated_ip_range = var.allocated_ip_range

  # Secondary clusters replicate the primary's users; passing an initial user
  # here is rejected. Backups below are NOT in the same category - they are
  # configured per-cluster and stay in effect on a secondary.
  cluster_initial_user = local.is_secondary ? null : {
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

  # NB: upstream takes machine_cpu_count/machine_type as flat attributes on
  # these objects - there is no nested machine_config block. Terraform drops
  # unrecognised attributes when converting to an object type constraint
  # instead of erroring, so getting this wrong sizes every instance at the
  # upstream default of 2 vCPU without any warning.
  primary_instance = {
    instance_id               = local.primary_instance_id
    display_name              = coalesce(var.primary_instance.display_name, local.primary_instance_id)
    availability_type         = var.primary_instance.availability_type
    machine_cpu_count         = var.primary_instance.cpu_count
    machine_type              = var.primary_instance.machine_type
    gce_zone                  = var.primary_instance.gce_zone
    database_flags            = var.primary_instance.database_flags
    labels                    = local.instance_labels
    annotations               = var.primary_instance.annotations
    ssl_mode                  = var.primary_instance.ssl_mode
    require_connectors        = var.primary_instance.require_connectors
    enable_public_ip          = var.primary_instance.enable_public_ip
    enable_outbound_public_ip = var.primary_instance.enable_outbound_public_ip
    cidr_range                = var.primary_instance.cidr_range
    query_insights_config     = var.primary_instance.query_insights_config
  }

  # display_name is a REQUIRED attribute on upstream's read_pool_instance
  # objects (unlike on primary_instance, where it is optional), so it has to be
  # populated for every entry or the whole plan fails.
  read_pool_instance = local.is_secondary ? [] : [
    for r in local.read_pool_instances : {
      instance_id           = r.instance_id
      display_name          = coalesce(r.display_name, r.instance_id)
      node_count            = r.node_count
      machine_cpu_count     = r.cpu_count
      machine_type          = r.machine_type
      database_flags        = r.database_flags
      ssl_mode              = r.ssl_mode
      require_connectors    = r.require_connectors
      enable_public_ip      = r.enable_public_ip
      cidr_range            = r.cidr_range
      query_insights_config = r.query_insights_config
    }
  ]
}
