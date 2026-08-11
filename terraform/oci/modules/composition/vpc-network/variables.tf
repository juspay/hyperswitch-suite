variable "compartment_id" {
  description = "OCID of the compartment to create networking resources in"
  type        = string
}

variable "vcn_name" {
  description = "Name of the VCN"
  type        = string
}

variable "vcn_cidr_blocks" {
  description = "CIDR blocks for the VCN (first is primary, rest are secondary CIDRs, mirrors AWS secondary_cidr_blocks)"
  type        = list(string)
}

variable "vcn_dns_label" {
  description = "DNS label for the VCN (must be unique within the compartment, alphanumeric, <=15 chars)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "enable_internet_gateway" {
  description = "Whether to create an Internet Gateway (equivalent to AWS create_internet_gateway)"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway for private subnet egress (equivalent to AWS enable_nat_gateway)"
  type        = bool
  default     = true
}

variable "enable_service_gateway" {
  description = "Whether to create a Service Gateway for private access to OCI services (Object Storage, etc) - closest OCI analog to an AWS S3 VPC Gateway Endpoint"
  type        = bool
  default     = true
}

variable "block_nat_traffic_via_service_gateway" {
  description = "If true, only route 'All <region> Services in Oracle Services Network' via the service gateway (recommended - avoids NAT egress cost for OCI-native traffic)"
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Subnet tiers
# ---------------------------------------------------------------------------
# OCI subnets are regional (not tied to a single Availability/Fault Domain
# like AWS subnets are tied to an AZ), so the AWS module's per-AZ subnet
# fan-out (external_incoming, management, eks_workers, eks_control_plane,
# database, locker_database, locker_server, elasticache, data_stack,
# incoming_envoy, outgoing_proxy, utils, lambda, + custom) collapses to one
# regional subnet per tier here. Compute/OKE node pools/LBs distribute
# across fault domains and ADs within a single regional subnet.
variable "subnet_tiers" {
  description = <<-EOT
    Map of subnet tier name -> config. Keys are expected to mirror the AWS
    tier names for symmetry, e.g. "external-incoming", "management",
    "eks-workers", "eks-control-plane", "database", "locker-database",
    "locker-server", "elasticache", "data-stack", "incoming-envoy",
    "outgoing-proxy", "utils", "functions".
  EOT
  type = map(object({
    cidr_block    = string
    dns_label     = string
    is_public     = optional(bool, false)
    route_via     = optional(string, "nat") # "igw" | "nat" | "none" (fully isolated, e.g. database tier)
    freeform_tags = optional(map(string), {})
  }))
  default = {}
}

variable "freeform_tags" {
  description = "Freeform tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to all resources"
  type        = map(string)
  default     = {}
}
