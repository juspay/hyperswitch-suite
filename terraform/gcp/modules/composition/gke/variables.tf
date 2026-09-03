variable "project_id" {
  description = "GCP project ID where the cluster is created"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster. Defaults to '<environment>-<project_name>-gke', or '<environment>-<project_name>-gke-<cluster_name_version>' if that's set. Setting this always wins outright over both."
  type        = string
  default     = null
}

variable "cluster_name_version" {
  description = "Optional numeric/version identifier appended to the default computed cluster name (\"<environment>-<project_name>-gke-<cluster_name_version>\"), for running more than one GKE cluster in the same environment and telling them apart - mirrors the AWS EKS module's identically-named variable (terraform/aws/modules/composition/eks, default \"v1\", live layers set \"01\") and that module's live-layer directory convention of naming the unit itself \"eks-01\"/\"eks-02\". Unlike AWS's version, this defaults to null (no suffix at all, i.e. the exact pre-existing name) rather than always appending something - google_container_cluster's name is a ForceNew attribute, so retroactively adopting AWS's always-on default against an already-named live cluster would force a full destroy-and-recreate of it. Only set this for a brand-new cluster, or when deliberately planning a rename (which will replace the cluster - do not set this on a live cluster's terragrunt.hcl without accepting that cost)."
  type        = string
  default     = null
}

variable "regional" {
  description = "Whether the cluster is regional (multi-zone control plane) or zonal"
  type        = bool
  default     = true
}

variable "region" {
  description = "Region to host the cluster in (required for regional clusters)"
  type        = string
}

variable "zones" {
  description = "Zones to host the cluster/nodes in (required for zonal clusters, optional otherwise)"
  type        = list(string)
  default     = []
}

variable "network" {
  description = "Self-link of the VPC network to host the cluster in"
  type        = string
}

variable "network_project_id" {
  description = "Project ID of the Shared VPC host project, if applicable"
  type        = string
  default     = ""
}

variable "subnetwork" {
  description = "Self-link of the subnetwork to host the cluster nodes in"
  type        = string
}

variable "ip_range_pods" {
  description = "Name of the secondary subnet IP range to use for pod alias IPs"
  type        = string
}

variable "ip_range_services" {
  description = "Name of the secondary subnet IP range to use for service alias IPs"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the control plane. 'latest' pulls the latest available version in the region"
  type        = string
  default     = "latest"
}

variable "release_channel" {
  description = "Release channel: UNSPECIFIED, RAPID, REGULAR, or STABLE"
  type        = string
  default     = "REGULAR"
}

variable "enable_private_endpoint" {
  description = "Whether the cluster's master is only accessible via its internal IP address"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "/28 CIDR block for the control plane's private network"
  type        = string
  default     = null
}

variable "create_master_egress_firewall_rule" {
  description = "Whether to create the EGRESS firewall rule allowing this cluster's nodes to reach its own private control-plane endpoint. GKE auto-creates the ingress side of node<->master traffic but never the egress side, so this is required for any private cluster (enable_private_nodes is always true in this module) once master_ipv4_cidr_block is set - true by default. Only skipped (regardless of this flag) when master_ipv4_cidr_block is null (nothing to allow egress to) or node_pools_tags is empty (would otherwise create a firewall rule with no target_tags, which GCP applies network-wide rather than to zero instances)."
  type        = bool
  default     = true
}

variable "master_authorized_networks" {
  description = "List of CIDR blocks allowed to access the Kubernetes master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "enable_network_policy" {
  description = "Enable the network policy addon (Calico)"
  type        = bool
  default     = false
}

variable "gateway_api_channel" {
  description = "Gateway API channel: CHANNEL_DISABLED, CHANNEL_EXPERIMENTAL, or CHANNEL_STANDARD"
  type        = string
  default     = "CHANNEL_STANDARD"
}

variable "create_service_account" {
  description = "Whether to create a dedicated node service account"
  type        = bool
  default     = true
}

variable "service_account" {
  description = "Existing service account email to run nodes as. Ignored if create_service_account is true"
  type        = string
  default     = ""
}

variable "logging_service" {
  description = "Logging service the cluster writes to"
  type        = string
  default     = "logging.googleapis.com/kubernetes"
}

variable "monitoring_service" {
  description = "Monitoring service the cluster writes to"
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
}

variable "kms_key_name" {
  description = "Cloud KMS CryptoKey self-link used for application-layer secrets (etcd) encryption. Null disables envelope encryption"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Whether to allow Terraform to destroy the cluster"
  type        = bool
  default     = true
}

variable "node_pools" {
  description = "List of node pool configuration maps, mirroring the upstream module's node_pools variable (name, machine_type, min_count, max_count, disk_size_gb, spot, etc.)"
  type        = list(map(any))
  default = [
    {
      name         = "default-pool"
      machine_type = "e2-standard-4"
      min_count    = 1
      max_count    = 5
      disk_size_gb = 100
      disk_type    = "pd-balanced"
      auto_repair  = true
      auto_upgrade = true
    },
  ]
}

variable "enable_node_auto_upgrade" {
  description = "Whether GKE is allowed to automatically upgrade node pool versions on its own schedule (tracking the cluster's release_channel). Defaults to false - node auto-upgrades replace running nodes without an explicit apply, which can surprise a live workload's reliability with a rollout nobody planned for (this is specifically about NODE version auto-upgrade, not the control-plane's own release_channel-driven upgrade cadence, which this module does not separately gate). Overrides every entry in var.node_pools' own auto_upgrade key uniformly (see locals.tf) rather than requiring every pool to remember to set it individually. Set true to restore GKE's own default self-managed node-upgrade behavior."
  type        = bool
  default     = false
}

variable "node_pools_labels" {
  description = "Map of node-pool name to Kubernetes labels applied to that pool's nodes"
  type        = map(map(string))
  default     = {}
}

variable "node_pools_taints" {
  description = "Map of node-pool name to a list of Kubernetes taints applied to that pool's nodes"
  type = map(list(object({
    key    = string
    value  = string
    effect = string
  })))
  default = {}
}

variable "node_pools_tags" {
  description = "Map of node-pool name to a list of GCE network tags applied to that pool's nodes"
  type        = map(list(string))
  default     = {}
}

variable "node_pools_metadata" {
  description = "Map of node-pool name to a map of additional instance metadata"
  type        = map(map(string))
  default     = {}
}

variable "node_pools_oauth_scopes" {
  description = "Map of node-pool name to a list of OAuth scopes granted to that pool's nodes"
  type        = map(list(string))
  default = {
    all = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

variable "labels" {
  description = "Additional labels applied to the cluster"
  type        = map(string)
  default     = {}
}
