###############################################################################
# General
###############################################################################

variable "compartment_id" {
  description = "OCID of the compartment every network resource is created in. OCI's unit of access control - there is no AWS or GCP analogue (a GCP project is the nearest concept, but one tenancy holds many compartments). Never hardcoded in the module; the catalog unit wires the real value."
  type        = string
}

variable "region" {
  description = "OCI region identifier, e.g. ap-mumbai-1. Used for naming and for resolving the service-gateway CIDR labels; subnets are regional so no availability-domain input exists."
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

variable "vcn_display_name" {
  description = "Display name of the VCN. Replaces the AWS module's vpc_name."
  type        = string
}

variable "freeform_tags" {
  description = "Freeform tags applied to every resource. Replaces the AWS module's tags."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags (namespace.key => value) applied to every resource. No AWS analogue - OCI defined tags are schema-controlled tenancy-level tags."
  type        = map(string)
  default     = {}
}

###############################################################################
# VCN
###############################################################################

variable "vcn_cidr_blocks" {
  description = "IPv4 CIDR blocks of the VCN. Replaces AWS's vpc_cidr + secondary_cidr_blocks: OCI models both as one updatable list. Limit 16 per VCN, each /16 to /30."
  type        = list(string)

  validation {
    condition     = length(var.vcn_cidr_blocks) >= 1 && length(var.vcn_cidr_blocks) <= 16
    error_message = "A VCN takes between 1 and 16 IPv4 CIDR blocks (OCI service limit, not increasable)."
  }
}

variable "vcn_dns_label" {
  description = "DNS label of the VCN; instances resolve as <host>.<subnet-label>.<vcn-label>.oraclevcn.com. Replaces AWS's enable_dns_hostnames / enable_dns_support pair - OCI has no equivalent booleans, the VCN resolver is always on and the label is what turns naming on. Max 15 alphanumeric chars, must start with a letter. NOT updatable: changing it forces VCN replacement. Defaults to a derived label."
  type        = string
  default     = null

  validation {
    condition     = var.vcn_dns_label == null || can(regex("^[a-zA-Z][a-zA-Z0-9]{0,14}$", coalesce(var.vcn_dns_label, "x")))
    error_message = "vcn_dns_label must start with a letter and contain only letters and digits, max 15 characters."
  }
}

variable "enable_ipv6" {
  description = "Allocate an Oracle-assigned IPv6 /56 GUA to the VCN. Subnet IPv6 ranges are always /64. Off by default, matching the AWS live roots."
  type        = bool
  default     = false
}

###############################################################################
# DHCP options
#
# PARTIAL parity: OCI supports exactly two option types, DomainNameServer and
# SearchDomain. No NTP option type exists (a mandated NTP source becomes an
# image-build concern); search_domain_names accepts exactly ONE entry; and
# custom_dns_servers is capped at 3.
###############################################################################

variable "create_dhcp_options" {
  description = "Create a non-default DHCP options set and attach it to every subnet this module creates. When false (default) subnets use the VCN default DHCP options, which is what all AWS live roots do today."
  type        = bool
  default     = false
}

variable "dhcp_dns_server_type" {
  description = "DomainNameServer option: VcnLocal, VcnLocalPlusInternet or CustomDnsServer. Applies to both the default DHCP options and the optional custom set."
  type        = string
  default     = "VcnLocalPlusInternet"

  validation {
    condition     = contains(["VcnLocal", "VcnLocalPlusInternet", "CustomDnsServer"], var.dhcp_dns_server_type)
    error_message = "dhcp_dns_server_type must be VcnLocal, VcnLocalPlusInternet or CustomDnsServer."
  }
}

variable "dhcp_custom_dns_servers" {
  description = "Up to 3 custom DNS server IPs, only meaningful when dhcp_dns_server_type = CustomDnsServer."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.dhcp_custom_dns_servers) <= 3
    error_message = "OCI accepts at most 3 custom DNS servers (not increasable); AWS allowed 4."
  }
}

variable "dhcp_search_domain_name" {
  description = "Single search domain handed to instances. OCI accepts exactly one, unlike AWS's list."
  type        = string
  default     = null
}

###############################################################################
# Gateways
###############################################################################

variable "create_internet_gateway" {
  description = "Create the VCN internet gateway. Limit 1 per VCN, not increasable - same shape as one IGW per VPC on AWS."
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Create the VCN NAT gateway. OCI's NAT gateway is a regional VCN-scoped service with a hard limit of 1 per VCN."
  type        = bool
  default     = true
}

variable "nat_reserved_public_ip_id" {
  description = "OCID of a reserved public IP to pin as the NAT gateway's egress address - the PSP/bank allowlistable IP, playing the role AWS's aws_eip plays. null lets Oracle assign an ephemeral public IP."
  type        = string
  default     = null
}

variable "nat_block_traffic" {
  description = "Blocks all traffic through the NAT gateway without destroying it. Kill switch with no AWS equivalent; false in normal operation."
  type        = bool
  default     = false
}

variable "enable_service_gateway_object_storage" {
  description = <<-EOT
    Attach the "OCI <region> Object Storage" service CIDR label to the service
    gateway. MUTUALLY EXCLUSIVE with enable_service_gateway_all_services -
    Oracle: "Because Object Storage is covered by both ... a service gateway
    can use only one of those service CIDR labels. Likewise, a route table can
    have a single rule for one of the service CIDR labels." Enabling both is
    not achievable; see the comment in gateways.tf.
  EOT
  type        = bool
  default     = false
}

variable "enable_service_gateway_all_services" {
  description = "Attach the \"All <region> Services in Oracle Services Network\" service CIDR label to the service gateway. This is the superset label and includes Object Storage. MUTUALLY EXCLUSIVE with enable_service_gateway_object_storage."
  type        = bool
  default     = true
}

###############################################################################
# Subnet CIDRs - one REGIONAL subnet per tier
#
# OCI subnets are regional by Oracle's recommendation, so each tier is one
# subnet (every *_subnet_cidrs list collapses to a *_subnet_cidr scalar); there
# is no availability_zones input. ap-mumbai-1 has one availability domain, so
# no in-region datacentre-failure spread is expressible here; fault-domain
# placement is a compute-module concern.
#
# Tiers dropped relative to AWS: eks-control-plane (the OKE control plane is
# Oracle-managed; only its API endpoint needs a subnet, see oke-api-endpoint)
# and lambda (no OCI Functions workload in the port yet - use utils).
###############################################################################

variable "external_incoming_subnet_cidr" {
  description = "CIDR for the internet-facing subnet (public load balancers)"
  type        = string
  default     = null
}

variable "management_subnet_cidr" {
  description = "CIDR for the bastion / jump-host subnet"
  type        = string
  default     = null
}

variable "oke_nodes_subnet_cidr" {
  description = "CIDR for the OKE worker node subnet. Replaces AWS's eks-workers tier."
  type        = string
  default     = null
}

variable "oke_pods_subnet_cidr" {
  description = "CIDR for OKE pod IPs under the VCN-native CNI (OCI_VCN_IP_NATIVE). New tier with no AWS or GCP counterpart: AWS put pods inside the node subnet's /22 and GCP used a secondary alias range, but OCI's VCN-native CNI takes a real subnet. Sized generously - one VCN IP per pod. Leave null to run the CNI in flannel-overlay mode instead."
  type        = string
  default     = null
}

variable "oke_api_endpoint_subnet_cidr" {
  description = "CIDR for the OKE Kubernetes API endpoint subnet (oci_containerengine_cluster endpoint_config.subnet_id). Not an eks-control-plane equivalent - the control plane itself is Oracle-managed and lives outside the VCN; only its endpoint VNIC lands here."
  type        = string
  default     = null
}

# 2026-09-06 (real, live finding): unlike AWS, OCI ties public reachability
# directly to this subnet's own public/private nature.
# `endpoint_config.is_public_ip_enabled = true` is rejected outright
# (400-InvalidParameter, "Invalid subnetId: must be a public subnet if public
# ip enabled") unless this subnet has an Internet Gateway route and allows a
# public IP on its VNIC. There is no OCI equivalent to AWS's decoupled model.
# Defaults false because this is a per-environment security decision.
#
# NOTE this is a real ForceNew on the underlying subnet
# (prohibit_public_ip_on_vnic cannot be flipped in place - OCI requires
# destroy-and-recreate), so flipping it on a live environment replaces that
# subnet. Prefer standing up a second, dedicated public subnet and repointing
# the oke unit's control_plane_subnet_id at it, rather than flipping this on a
# live environment.
#
# This toggle and a Bastion service are complementary, not either/or - Oracle's
# recommended production pattern is a private cluster reached via the Bastion
# service regardless of this setting.
variable "oke_api_endpoint_is_public" {
  description = "Whether a SECOND, additive OKE API endpoint subnet (oke-api-endpoint-public) is created and made the cluster's active endpoint subnet, matching AWS EKS's cluster_endpoint_public_access = true behaviour. Defaults false. The original private subnet is never touched by this toggle - recreating it in place deadlocks against the cluster's own Oracle-managed Service VNIC. Flip alongside the oke unit's own control_plane_is_public / assign_public_ip_to_control_plane and its control_plane_subnet_id selection."
  type        = bool
  default     = false
}

# The additive public subnet's own CIDR. Must not overlap any other tier - it
# must coexist with the private subnet while the toggle is on (the private one
# is never destroyed), so pick a distinct block (oke_api_endpoint_subnet_cidr
# already claims one /24).
variable "oke_api_endpoint_public_subnet_cidr" {
  description = "CIDR for the additive, public-only OKE API endpoint subnet (oke-api-endpoint-public). Only actually created when oke_api_endpoint_is_public = true - see that variable and locals.tf's all_subnets null-CIDR convention."
  type        = string
  default     = null
}

variable "database_subnet_cidr" {
  description = "CIDR for the database subnet"
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

variable "cache_subnet_cidr" {
  description = "CIDR for the OCI Cache (Valkey) subnet. Replaces AWS's elasticache tier."
  type        = string
  default     = null
}

variable "data_stack_subnet_cidr" {
  description = "CIDR for the Kafka / Cassandra / ClickHouse / OpenSearch data-stack subnet"
  type        = string
  default     = null
}

variable "incoming_envoy_subnet_cidr" {
  description = "CIDR for the Envoy ingress proxy subnet"
  type        = string
  default     = null
}

variable "outgoing_proxy_subnet_cidr" {
  description = "CIDR for the Squid egress proxy subnet - the only tier with a NAT route"
  type        = string
  default     = null
}

variable "utils_subnet_cidr" {
  description = "CIDR for shared utility workloads"
  type        = string
  default     = null
}

variable "custom_subnets" {
  description = "Additional subnets keyed by tier name, merged alongside the named tiers. Escape hatch matching the GCP module's custom_subnets; route_table must name a key of the route-table catalogue in locals.tf, defaulting to the fully isolated common-local table."
  type = map(object({
    cidr                       = string
    prohibit_public_ip_on_vnic = optional(bool, true)
    route_table                = optional(string, "common-local")
    dns_label                  = optional(string)
    description                = optional(string)
  }))
  default = {}
}

###############################################################################
# Flow logs
###############################################################################

variable "enable_flow_logs" {
  description = "Enable VCN flow logs. One oci_logging_log with category \"vcn\" covers existing and future VNICs in every subnet, so unlike AWS there is no per-subnet fan-out and no single VPC-level flow-log resource to mirror."
  type        = bool
  default     = false
}

variable "flow_logs_log_group_id" {
  description = "OCID of an existing oci_logging_log_group to write flow logs into. null creates a log group in this module."
  type        = string
  default     = null
}

variable "flow_logs_retention_duration" {
  description = "Flow log retention in days (30-180)"
  type        = number
  default     = 30
}

###############################################################################
# Peering
#
# OCI splits AWS's single peering construct three ways, so the AWS input pair
# cannot survive as one input:
#   - same-region      -> Local Peering Gateway, one per side, 10 per VCN
#   - cross-region     -> DRG + Remote Peering Connection
#   - cross-tenancy    -> either of the above PLUS IAM policy statements in
#                         both tenancies (the peer_owner_id field has no
#                         counterpart; the policies are out of scope here)
# The requester/accepter distinction disappears: an LPG is symmetric, and
# whichever side sets peer_id establishes the connection.
###############################################################################

variable "local_peering_gateways" {
  description = "Same-region VCN peerings, keyed by name. peer_id is the OCID of the peer's LPG; leave it null on the side that waits to be connected. peer_cidrs are the destinations routed over the LPG, route_tables names route-table catalogue keys or the groups all/public/private-nat/private-isolated/database/oke-nodes."
  type = map(object({
    peer_id      = optional(string)
    peer_cidrs   = optional(list(string), [])
    route_tables = optional(list(string), ["all"])
  }))
  default = {}
}

variable "create_drg" {
  description = "Create a Dynamic Routing Gateway and attach this VCN to it. Required for cross-region remote peering, FastConnect and Site-to-Site VPN. Ignored when drg_id is set."
  type        = bool
  default     = false
}

variable "drg_id" {
  description = "OCID of an existing DRG to attach this VCN to instead of creating one."
  type        = string
  default     = null
}

variable "remote_peering_connections" {
  description = "Cross-region peerings over the DRG, keyed by name. Requires create_drg or drg_id."
  type = map(object({
    peer_id          = optional(string)
    peer_region_name = optional(string)
    peer_cidrs       = optional(list(string), [])
    route_tables     = optional(list(string), ["all"])
  }))
  default = {}
}

variable "enable_peering_routes" {
  description = "Whether to expand peer CIDRs into route rules on the named route tables. Ports AWS's enable_vpc_peering_routes unchanged in meaning."
  type        = bool
  default     = true
}
