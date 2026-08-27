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
