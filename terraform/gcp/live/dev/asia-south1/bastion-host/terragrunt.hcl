include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_self_link = "projects/mock/global/networks/mock-vpc"
    subnets_by_tier   = { management = "projects/mock/regions/asia-south1/subnetworks/mock-management" }
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "alloydb" {
  config_path = "../alloydb"

  mock_outputs = {
    primary_instance_ip = "10.214.0.1"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "valkey" {
  config_path = "../memorystore-valkey"

  mock_outputs = {
    discovery_host = "10.2.74.1"
    discovery_port = 6379
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "../../../../modules/composition/bastion-host"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region
  zone         = "asia-south1-b"

  network = dependency.vpc.outputs.network_self_link
  subnet  = dependency.vpc.outputs.subnets_by_tier["management"]

  machine_type = include.root.locals.machine_types.bastion
  disk_size_gb = 20
  disk_type    = "pd-balanced"

  image = "projects/debian-cloud/global/images/family/debian-12"

  members = include.root.locals.bastion_iap_members

  connection_targets = {
    alloydb = {
      host = dependency.alloydb.outputs.primary_instance_ip
      port = 5432

      description = "AlloyDB primary - psql 'host=127.0.0.1 port=5432 user=hyperswitch_admin sslmode=require'"
    }

    valkey = {
      host = dependency.valkey.outputs.discovery_host
      port = dependency.valkey.outputs.discovery_port

      description = "Memorystore Valkey cluster discovery endpoint - valkey-cli -h 127.0.0.1 -p 6379"
    }
  }

  additional_service_account_roles = [
    "roles/secretmanager.secretAccessor",
  ]

  enable_session_logging = false

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "bastion-host"
    managed_by  = "terraform"
  }
}
