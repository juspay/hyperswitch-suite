include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_id                        = "projects/mock/global/networks/mock-vpc"
    private_service_access_range_name = "mock-psa-range"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "gke" {
  config_path = "../application-stack/gke"

  mock_outputs = {
    cluster_name   = "mock-cluster"
    location       = "asia-south1"
    endpoint       = "mock-endpoint"
    ca_certificate = "bW9jaw=="
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "../../../..//modules/composition/locker"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  cluster_name     = dependency.gke.outputs.cluster_name
  cluster_location = dependency.gke.outputs.location

  cluster_endpoint       = dependency.gke.outputs.endpoint
  cluster_ca_certificate = dependency.gke.outputs.ca_certificate

  k8s_namespace            = "hyperswitch"
  k8s_service_account_name = "hyperswitch-vault-role"

  use_existing_k8s_sa = true

  annotate_k8s_sa = false

  additional_project_roles = []

  create_database = true

  database_config = {
    network_id = dependency.vpc.outputs.network_id

    allocated_ip_range = dependency.vpc.outputs.private_service_access_range_name

    availability_type = "ZONAL"
    cpu_count         = 2

    deletion_protection = false

    master_username = "locker_admin"

    secret_manager = {
      create = true
    }
  }

  create_kms_key = true
  kms_key_id     = "locker"

  kms_protection_level = "SOFTWARE"
  kms_rotation_period  = "7776000s"

  kms_prevent_destroy = true

  grant_kms_access = false

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    compliance  = "pci-dss"
    managed_by  = "terraform"
  }
}
