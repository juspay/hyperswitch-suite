# Grafana: a GSA plus a Workload Identity binding, and an optional dedicated
# AlloyDB cluster via composition/alloydb, configured through a single
# database_config object.

# The workload_identity module below creates a real kubernetes_service_account_v1;
# without a configured provider it falls back to the zero-config default and
# apply fails with `dial tcp [::1]:80: connect: connection refused`. Declaring
# the provider here rather than in the live layer keeps the live-layer files
# free of embedded Terraform.
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

  use_existing_k8s_sa = var.use_existing_k8s_sa
  annotate_k8s_sa     = var.annotate_k8s_sa

  roles = var.additional_project_roles
}

module "database" {
  source = "../../composition/alloydb"

  count = var.create_database ? 1 : 0

  project_id   = var.project_id
  environment  = var.environment
  project_name = "${var.project_name}-grafana"
  region       = var.region

  network_id         = var.database_config.network_id
  allocated_ip_range = var.database_config.allocated_ip_range

  cluster_id          = var.database_config.cluster_id
  database_version    = coalesce(var.database_config.database_version, "POSTGRES_15")
  deletion_protection = coalesce(var.database_config.deletion_protection, true)

  master_username = coalesce(var.database_config.master_username, "grafana_admin")
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
