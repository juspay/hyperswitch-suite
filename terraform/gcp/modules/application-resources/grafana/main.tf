# ============================================================================
# Grafana (GCP equivalent of application-resources/grafana)
# ============================================================================
# GSA + Workload Identity binding, plus an optional dedicated Cloud SQL
# database via composition/cloud-sql. Unlike the AWS module - which flattens
# ~60 database_* variables directly - this module takes a single
# database_config object (matching application-resources/superposition's
# style rather than grafana's, resolving the interface inconsistency
# between the two AWS callers of the shared database module).
#
# Usage:
#   module "grafana" {
#     source = "../../modules/application-resources/grafana"
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
#
#     host_domains = { grafana = "grafana.dev.hyperswitch.example.com" }
#   }
# ============================================================================

# ==============================================================================
# This module's own kubernetes provider.
#
# `../gke-workload-identity` (below) wraps terraform-google-modules/
# kubernetes-engine//modules/workload-identity, which creates a real
# `kubernetes_service_account_v1`. With no configured kubernetes provider
# that resource falls back to the provider's zero-config default and apply
# fails with `dial tcp [::1]:80: connect: connection refused`. Declaring the
# provider here (rather than in the live layer via a Terragrunt `generate`
# block) keeps the live-layer files free of embedded Terraform - default-
# provider inheritance makes this config available to the child module.
# Same pattern as ../hyperswitch, ../superposition and ../istio.
# ==============================================================================
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
  app_name     = "grafana"

  cluster_name             = var.cluster_name
  cluster_location         = var.cluster_location
  k8s_namespace            = var.k8s_namespace
  k8s_service_account_name = var.k8s_service_account_name

  use_existing_k8s_sa = var.use_existing_k8s_sa
  annotate_k8s_sa     = var.annotate_k8s_sa

  project_roles = var.additional_project_roles

  labels = local.common_labels
}

module "database" {
  source = "../../composition/cloud-sql"

  count = var.create_database ? 1 : 0

  project_id   = var.project_id
  environment  = var.environment
  project_name = "${var.project_name}-grafana"
  region       = var.region
  network_id   = var.database_config.network_id

  instance_name       = var.database_config.instance_name
  database_version    = coalesce(var.database_config.database_version, "POSTGRES_15")
  tier                = coalesce(var.database_config.tier, "db-custom-2-8192")
  availability_type   = coalesce(var.database_config.availability_type, "REGIONAL")
  disk_size           = coalesce(var.database_config.disk_size, 50)
  deletion_protection = coalesce(var.database_config.deletion_protection, true)

  database_name   = coalesce(var.database_config.database_name, "grafana")
  master_username = coalesce(var.database_config.master_username, "grafana_admin")
  master_password = var.database_config.master_password

  encryption_key_name = var.database_config.encryption_key_name

  labels = local.common_labels
}
