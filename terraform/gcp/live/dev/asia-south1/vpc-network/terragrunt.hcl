include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../..//modules/composition/vpc-network"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  network_name = "hyperswitch-dev-vpc"
  routing_mode = "GLOBAL"

  external_incoming_subnet_cidr = "10.2.64.0/24"
  management_subnet_cidr        = "10.2.67.0/24"

  gke_nodes_subnet_cidr             = "10.2.32.0/20"
  gke_pods_secondary_range_cidr     = "10.100.0.0/16"
  gke_services_secondary_range_cidr = "10.101.0.0/20"

  database_subnet_cidr             = "10.2.73.0/24"
  memorystore_subnet_cidr          = "10.2.74.0/24"
  locker_database_subnet_cidr      = "10.2.75.0/24"
  locker_server_subnet_cidr        = "10.2.76.0/24"
  outgoing_proxy_subnet_cidr       = "10.2.77.0/24"
  data_stack_subnet_cidr           = "10.2.80.0/24"
  serverless_connector_subnet_cidr = "10.2.90.0/28"

  custom_subnets = {}

  enable_flow_logs = false

  router_asn           = 64514
  nat_min_ports_per_vm = 64
  nat_subnetwork_tiers = ["outgoing-proxy"]
  nat_log_filter       = "ALL"

  enable_default_deny_egress = true
  enable_psc_google_apis     = true

  private_service_access_prefix_length = 16

  vpc_internal_ranges = {
    primary  = "10.2.0.0/16"
    gke_pods = "10.100.0.0/16"
    gke_svcs = "10.101.0.0/20"

    psa = "10.214.0.0/16"
  }
  enable_default_deny_ingress = true

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    team        = "infra"
    managed_by  = "terraform"
  }
}
