# Superposition: a GSA plus a Workload Identity binding, and an optional
# dedicated AlloyDB cluster via composition/alloydb, configured through a single
# database_config object.

data "google_client_config" "current" {}

provider "kubernetes" {
  host                   = "https://${var.cluster_endpoint}"
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = data.google_client_config.current.access_token
}

module "workload_identity" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "44.3.0"

  project_id = var.project_id
  name       = local.gcp_sa_name

  cluster_name = var.cluster_name
  location     = var.cluster_location
  namespace    = var.k8s_namespace
  k8s_sa_name  = var.k8s_service_account_name

  roles = var.additional_project_roles
}

module "database" {

  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/alloydb?ref=gcp-alloydb-v0.1.0"

  count = var.create_database ? 1 : 0

  project_id   = var.project_id
  environment  = var.environment
  project_name = "${var.project_name}-superposition"
  region       = var.region

  network_id         = var.database_config.network_id
  allocated_ip_range = var.database_config.allocated_ip_range

  cluster_id          = var.database_config.cluster_id
  database_version    = coalesce(var.database_config.database_version, "POSTGRES_15")
  deletion_protection = coalesce(var.database_config.deletion_protection, true)

  master_username = coalesce(var.database_config.master_username, "superposition_admin")
  master_password = var.database_config.master_password

  # AlloyDB has exactly one primary instance per cluster, and its storage is
  # service-managed rather than provisioned up front.
  primary_instance = {
    availability_type = coalesce(var.database_config.availability_type, "REGIONAL")
    cpu_count         = coalesce(var.database_config.cpu_count, 2)
    machine_type      = var.database_config.machine_type
    database_flags    = var.database_config.database_flags
  }

  encryption_key_name = var.database_config.encryption_key_name
  secret_manager      = var.database_config.secret_manager

  labels = local.common_labels
}
