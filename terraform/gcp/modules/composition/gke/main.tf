# Standard (non-Autopilot) private GKE cluster: private nodes, explicit node
# pools, and Workload Identity enabled cluster-wide - application-resources
# modules bind individual KSA<->GSA pairs on top of this.
#
# Autopilot is deliberately not used: it does not allow the per-node-pool
# taints/labels/DaemonSets that vector, otel-collector and the istio gateways
# rely on.

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "44.3.0"

  project_id  = var.project_id
  name        = local.cluster_name
  description = "Hyperswitch ${var.environment} GKE cluster"

  regional = var.regional
  region   = var.region
  zones    = var.zones

  network            = var.network
  network_project_id = var.network_project_id
  subnetwork         = var.subnetwork
  ip_range_pods      = var.ip_range_pods
  ip_range_services  = var.ip_range_services

  kubernetes_version = var.kubernetes_version
  release_channel    = var.release_channel

  enable_private_nodes    = true
  enable_private_endpoint = var.enable_private_endpoint
  master_ipv4_cidr_block  = var.master_ipv4_cidr_block

  master_authorized_networks = var.master_authorized_networks

  horizontal_pod_autoscaling = true
  http_load_balancing        = true
  network_policy             = var.enable_network_policy
  gateway_api_channel        = var.gateway_api_channel

  identity_namespace = "enabled" # Workload Identity, cluster-wide

  create_service_account = var.create_service_account
  service_account        = var.service_account
  grant_registry_access  = true

  logging_service    = var.logging_service
  monitoring_service = var.monitoring_service

  database_encryption = var.kms_key_name != null ? [{
    state    = "ENCRYPTED"
    key_name = var.kms_key_name
  }] : [{ state = "DECRYPTED", key_name = "" }]

  deletion_protection      = var.deletion_protection
  remove_default_node_pool = true
  initial_node_count       = 1

  node_pools              = local.node_pools
  node_pools_labels       = var.node_pools_labels
  node_pools_taints       = var.node_pools_taints
  node_pools_tags         = var.node_pools_tags
  node_pools_metadata     = var.node_pools_metadata
  node_pools_oauth_scopes = var.node_pools_oauth_scopes

  cluster_resource_labels = local.common_labels
}

# Node -> control plane egress. Required for any private cluster: GKE
# auto-creates the ingress side of node<->master traffic but never the egress
# side, so without this nodes cannot reach their own control plane to register.
#
# Lives here rather than in composition/firewall-rules because both source and
# destination are owned entirely by this module. The name is kept exactly as it
# was when the rule lived in that unit, so the live layer could import the
# existing GCP resource rather than recreate it.
resource "google_compute_firewall" "allow_egress_to_master" {
  count = (
    var.master_ipv4_cidr_block != null &&
    var.create_master_egress_firewall_rule &&
    length(distinct(flatten(values(var.node_pools_tags)))) > 0
  ) ? 1 : 0

  name        = "${local.name_prefix}-gke-egress-to-master-allow-gke-to-master"
  project     = var.project_id
  network     = var.network
  direction   = "EGRESS"
  priority    = 1000
  description = "Allow this cluster's nodes to reach its own private control-plane endpoint - kubelet/API (443), metrics/reverse-tunnel (10250), and the mandatory konnectivity-agent tunnel (8132). GKE auto-creates the ingress side of this traffic but never egress."

  destination_ranges = [var.master_ipv4_cidr_block]
  target_tags        = distinct(flatten(values(var.node_pools_tags)))

  allow {
    protocol = "tcp"
    ports    = ["443", "10250", "8132"]
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}
