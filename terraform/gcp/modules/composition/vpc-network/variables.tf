# ==============================================================================
# General
# ==============================================================================

variable "project_id" {
  description = "GCP project ID where the network is created"
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

variable "region" {
  description = "Region all subnets and regional resources (router, NAT, PSA) are created in"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "routing_mode" {
  description = "Network routing mode: GLOBAL or REGIONAL"
  type        = string
  default     = "GLOBAL"
}

variable "mtu" {
  description = "Maximum transmission unit for the VPC"
  type        = number
  default     = 1460
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# Subnet CIDRs (one regional subnet per tier - see locals.tf for the full list)
# ==============================================================================

variable "external_incoming_subnet_cidr" {
  description = "CIDR for the internet-facing (external load balancer) subnet"
  type        = string
}

variable "management_subnet_cidr" {
  description = "CIDR for the bastion/jump-host subnet"
  type        = string
}

variable "gke_nodes_subnet_cidr" {
  description = "Primary CIDR for the GKE node pool subnet"
  type        = string
}

variable "gke_pods_secondary_range_cidr" {
  description = "Secondary range CIDR for GKE pod alias IPs"
  type        = string
}

variable "gke_services_secondary_range_cidr" {
  description = "Secondary range CIDR for GKE service alias IPs"
  type        = string
}

variable "database_subnet_cidr" {
  description = "CIDR for the database-adjacent subnet (Cloud SQL proxies, private consumers)"
  type        = string
  default     = null
}

variable "locker_database_subnet_cidr" {
  description = "CIDR for the PCI-DSS scoped locker database subnet"
  type        = string
  default     = null
}

variable "locker_server_subnet_cidr" {
  description = "CIDR for the PCI-DSS scoped locker server subnet"
  type        = string
  default     = null
}

variable "memorystore_subnet_cidr" {
  description = "Reserved CIDR range for Memorystore direct-peering instances"
  type        = string
  default     = null
}

variable "data_stack_subnet_cidr" {
  description = "CIDR for the Kafka/Cassandra/ClickHouse/OpenSearch data-stack subnet"
  type        = string
  default     = null
}

variable "incoming_envoy_subnet_cidr" {
  description = "CIDR for the Envoy ingress proxy subnet"
  type        = string
  default     = null
}

variable "outgoing_proxy_subnet_cidr" {
  description = "CIDR for the Squid egress proxy subnet"
  type        = string
  default     = null
}

variable "utils_subnet_cidr" {
  description = "CIDR for shared utility workloads"
  type        = string
  default     = null
}

variable "serverless_connector_subnet_cidr" {
  description = "CIDR (/28) for the Serverless VPC Access connector used by Cloud Functions/Cloud Run"
  type        = string
  default     = null
}

variable "custom_subnets" {
  description = "Additional custom subnets keyed by tier name, merged alongside the named tiers"
  type = map(object({
    cidr                     = string
    private_ip_google_access = optional(bool, true)
    purpose                  = optional(string)
    description              = optional(string)
    secondary_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
  }))
  default = {}
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs on every created subnet"
  type        = bool
  default     = false
}

# ==============================================================================
# Cloud Router / Cloud NAT
# ==============================================================================

variable "router_asn" {
  description = "BGP ASN for the Cloud Router"
  type        = number
  default     = 64514
}

variable "nat_min_ports_per_vm" {
  description = "Minimum number of ports allocated per VM for Cloud NAT"
  type        = number
  default     = 64
}

variable "nat_log_filter" {
  description = "Cloud NAT log_config_filter: ERRORS_ONLY (default, unchanged behavior), TRANSLATIONS_ONLY, or ALL. Set to ALL when pairing with nat_subnetwork_tiers to get a full audit trail of everything actually leaving via NAT (e.g. Squid's own egress) - safe to do once NAT is scoped down to a small subnet, since log volume is naturally bounded."
  type        = string
  default     = "ERRORS_ONLY"
}

variable "nat_static_ip_count" {
  description = "Number of static external IPs to reserve and assign to Cloud NAT for a stable, allowlistable egress IP (e.g. PSP/bank IP allowlisting for connector traffic). 0 (default) leaves Cloud NAT on GCP's auto-allocated ephemeral IPs (AUTO_ONLY); a nonzero value reserves that many google_compute_address resources and switches Cloud NAT to MANUAL_ONLY."
  type        = number
  default     = 0
}

variable "nat_subnetwork_tiers" {
  description = <<-EOT
    Restricts Cloud NAT to only the named subnet tiers (keys from the
    named_subnets map in locals.tf, e.g. ["outgoing-proxy"]), switching Cloud
    NAT from the default ALL_SUBNETWORKS_ALL_IP_RANGES mode to
    LIST_OF_SUBNETWORKS mode. Any tier NOT listed here gets no NAT route at
    all - this mirrors AWS's eks-worker-s3-only route table pattern
    (create_nat_gateway_route = false on the EKS worker route table), where
    only the Squid/outgoing-proxy subnet has a route to the internet and
    everything else must proxy through it for PCI-relevant egress control.
    null (default) preserves today's behavior: every subnet's every IP range
    (including GKE pods/services secondary ranges) gets a NAT route.
  EOT
  type        = list(string)
  default     = null
}

variable "enable_default_deny_egress" {
  description = <<-EOT
    Whether to replace the module's default allow-all-egress rule with a
    lowest-priority default-deny-all egress rule. false (default) preserves
    today's behavior (unrestricted egress to 0.0.0.0/0). When true, all
    egress destinations must be explicitly allowed elsewhere (e.g.
    composition/firewall-rules) - pair with nat_subnetwork_tiers so GKE
    nodes/pods have neither a NAT route nor a firewall allow straight to the
    internet, forcing traffic through an explicitly allowlisted path (e.g.
    Squid) instead. Mirrors AWS's eks_node_egress security group, which has
    no 0.0.0.0/0 allow at all - only specific per-destination allows.

    IMPORTANT: also set enable_psc_google_apis = true before enabling this,
    unless every subnet that needs Artifact Registry/other Google API access
    already has another explicit egress allow for it - without a Private
    Service Connect (internal-IP) path to Google APIs, plain
    private_ip_google_access traffic still resolves to Google's public IP
    ranges and would be blocked by this deny-all, breaking image pulls.
  EOT
  type        = bool
  default     = false
}

# ==============================================================================
# Private Service Connect for Google APIs
# ==============================================================================

variable "enable_psc_google_apis" {
  description = <<-EOT
    Adds a Private Service Connect (PSC) endpoint for Google APIs
    (forwarding_rule_target = "all-apis") plus private DNS zones for
    googleapis.com/gcr.io/pkg.dev bound to this VPC, so Artifact Registry and
    other Google API traffic resolves to an internal IP inside the VPC
    instead of Google's public IP ranges. false (default) leaves Google API
    access on today's plain Private Google Access path (subnet-level
    private_ip_google_access, still routed toward Google's public IPs via
    the subnet's default internet-gateway system route).

    This is the GCP-native equivalent of AWS's ecr_api/ecr_dkr interface VPC
    endpoints, and is required (not merely additive) before enabling
    enable_default_deny_egress and/or restricting nat_subnetwork_tiers on
    any subnet that needs to reach Artifact Registry, Secret Manager, or
    other Google APIs - without it, those calls have no path once general
    internet egress/NAT is locked down.
  EOT
  type        = bool
  default     = false
}

variable "psc_google_apis_ip" {
  description = "Internal IP address reserved for the Private Service Connect Google APIs endpoint. Must not collide with any subnet CIDR, the Private Service Access range, or any other reserved address in the VPC. Only used when enable_psc_google_apis = true."
  type        = string
  default     = "10.255.255.254"
}

# ==============================================================================
# Private Service Access (Cloud SQL / Memorystore)
# ==============================================================================

variable "private_service_access_prefix_length" {
  description = "Prefix length of the reserved IP range for Private Service Access peering"
  type        = number
  default     = 16
}

# ==============================================================================
# Baseline Firewall Rules
# ==============================================================================

variable "vpc_internal_ranges" {
  description = "Map of CIDR ranges considered internal to the VPC, allowed to talk to each other on the allow-internal rule"
  type        = map(string)
}

variable "enable_default_deny_ingress" {
  description = "Whether to add a lowest-priority default-deny-all ingress rule"
  type        = bool
  default     = true
}
