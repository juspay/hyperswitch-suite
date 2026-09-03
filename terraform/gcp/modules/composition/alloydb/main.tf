# AlloyDB cluster. Wraps the Google-maintained registry module rather than the
# native google_alloydb_cluster resource, whose dynamic network_config/psc_config
# blocks have a known provider bug (hashicorp/terraform-provider-google#18481).
#
# Reuses composition/vpc-network's Private Service Access setup: network_id and
# allocated_ip_range come from that module's outputs.
#
# Cross-region DR: leaving primary_cluster_name unset gives a standalone
# PRIMARY. A second instantiation in another region, pointed at this one's
# `cluster_name` output, becomes a SECONDARY - the PSA range is global and the
# peering per-network, so it reuses the same network_id/allocated_ip_range. A
# secondary inherits the primary's users and cannot host read pools. Promotion
# and switchover are manual gcloud operations; see README.
#
# AlloyDB allows exactly one primary per cluster - read scaling is via read
# pools, each a single instance fronting node_count nodes.

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

  # The service-agent CMEK grant must land BEFORE the instance is created;
  # nothing in the arguments below references it, so the ordering has to be
  # stated explicitly or Terraform is free to create the instance first.
  depends_on = [google_kms_crypto_key_iam_member.alloydb_service_agent]

  project_id = var.project_id
  cluster_id = local.cluster_id
  location   = var.region

  # Upstream derives SECONDARY from primary_cluster_name; set explicitly to
  # keep the intent readable here.
  cluster_type         = local.is_secondary ? "SECONDARY" : "PRIMARY"
  primary_cluster_name = var.primary_cluster_name
  database_version     = var.database_version
  cluster_labels       = local.common_labels
  cluster_display_name = local.cluster_id

  network_self_link  = var.network_id
  allocated_ip_range = var.allocated_ip_range

  # Secondary clusters replicate the primary's users, so an initial user is
  # rejected. Backups are per-cluster and do stay in effect on a secondary.
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

  # Upstream takes machine_cpu_count/machine_type as flat attributes; there is
  # no nested machine_config block. Terraform silently drops unrecognised
  # attributes, so a nested block would size every instance at the 2 vCPU
  # default without warning.
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

  # display_name is required on upstream's read_pool_instance objects (unlike
  # on primary_instance), so every entry must set it.
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
