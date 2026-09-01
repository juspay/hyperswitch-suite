# ============================================================================
# Superposition (GCP equivalent of application-resources/superposition)
# ============================================================================
# GSA + Workload Identity binding, plus an optional dedicated Cloud SQL
# database via composition/cloud-sql, called with the same single
# database_config object style as application-resources/grafana (the AWS
# side had grafana and superposition calling the same database module with
# two different interface styles; both GCP callers now agree).
#
# Usage:
#   module "superposition" {
#     source = "../../modules/application-resources/superposition"
#
#     project_id   = "hyperswitch-dev"
#     environment  = "dev"
#     project_name = "hyperswitch"
#     region       = "europe-west1"
#
#     cluster_name     = module.gke.cluster_name
#     cluster_location = module.gke.location
#
#     database_config = {
#       network_id = module.vpc_network.network_id
#     }
#   }
# ============================================================================

data "google_client_config" "current" {}

provider "kubernetes" {
  host                   = "https://${var.cluster_endpoint}"
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = data.google_client_config.current.access_token
}

module "workload_identity" {
  source = "../gke-workload-identity"

  project_id   = var.project_id
  environment  = var.environment
  project_name = var.project_name
  app_name     = "superposition"

  cluster_name             = var.cluster_name
  cluster_location         = var.cluster_location
  k8s_namespace            = var.k8s_namespace
  k8s_service_account_name = var.k8s_service_account_name

  project_roles = var.additional_project_roles

  labels = local.common_labels
}

module "database" {
  source = "../../composition/cloud-sql"

  count = var.create_database ? 1 : 0

  project_id   = var.project_id
  environment  = var.environment
  project_name = "${var.project_name}-superposition"
  region       = var.region
  network_id   = var.database_config.network_id

  instance_name       = var.database_config.instance_name
  database_version    = coalesce(var.database_config.database_version, "POSTGRES_15")
  tier                = coalesce(var.database_config.tier, "db-custom-2-8192")
  availability_type   = coalesce(var.database_config.availability_type, "REGIONAL")
  disk_size           = coalesce(var.database_config.disk_size, 50)
  deletion_protection = coalesce(var.database_config.deletion_protection, true)

  database_name   = coalesce(var.database_config.database_name, "superposition")
  master_username = coalesce(var.database_config.master_username, "superposition_admin")
  master_password = var.database_config.master_password

  encryption_key_name = var.database_config.encryption_key_name

  labels = local.common_labels
}
