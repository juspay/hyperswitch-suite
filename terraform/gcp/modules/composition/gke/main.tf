# ============================================================================
# GKE Cluster (GCP equivalent of composition/eks)
# ============================================================================
# Standard (non-Autopilot) private-cluster GKE, matching the AWS EKS module's
# shape: private nodes, explicit node pools, and IRSA-equivalent Workload
# Identity enabled cluster-wide (application-resources modules bind
# individual KSA<->GSA pairs on top of this).
#
# Autopilot was intentionally not used here: it does not allow per-node-pool
# taints/labels/DaemonSets, which vector, otel-collector, and the istio
# gateways rely on (see terraform/gcp/modules/README.md).
#
# Usage:
#   module "gke" {
#     source = "../../modules/composition/gke"
#
#     project_id   = "hyperswitch-dev"
#     environment  = "dev"
#     region       = "europe-west1"
#     network      = module.vpc_network.network_self_link
#     subnetwork   = module.vpc_network.gke_nodes_subnet_self_link
#     ip_range_pods     = module.vpc_network.gke_pods_secondary_range_name
#     ip_range_services = module.vpc_network.gke_services_secondary_range_name
#   }
# ============================================================================

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

  node_pools              = var.node_pools
  node_pools_labels       = var.node_pools_labels
  node_pools_taints       = var.node_pools_taints
  node_pools_tags         = var.node_pools_tags
  node_pools_metadata     = var.node_pools_metadata
  node_pools_oauth_scopes = var.node_pools_oauth_scopes

  cluster_resource_labels = local.common_labels
}

# ==============================================================================
# Node -> Control Plane Egress Firewall Rule
# ==============================================================================
# Required for any private GKE cluster (enable_private_nodes is always true
# above): GKE auto-creates the ingress side of node<->master traffic but
# never the egress side. Without this, nodes can never reach their own
# control plane to register - not an edge case, a hard requirement whenever
# master_ipv4_cidr_block is set. Lives here rather than in a separate
# cross-cutting firewall-rules unit because both source (this cluster's own
# nodes) and destination (this cluster's own master) are wholly owned by
# this module - same reasoning as Envoy/Squid creating their own
# internal-LB health-check rules instead of relying on a shared unit for
# something that's entirely their own concern. This is what lets a plain
# `vpc-network -> gke` flow produce a cluster whose nodes can actually
# register, with firewall-rules only needed for genuinely cross-component
# paths (e.g. GKE -> Squid), not as a hard prerequisite for gke itself.
#
# 2026-08-31: this exact name matches a rule that previously lived in
# composition/firewall-rules (component "gke-egress-to-master", rule name
# "allow-gke-to-master") - kept identical so the live layer's migration
# could `terraform import` the already-live GCP resource into this
# module's state instead of destroying and recreating it.
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
