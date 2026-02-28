###################
# Create Control
###################
variable "create" {
  description = "Controls if resources should be created"
  type        = bool
  default     = true
}

###################
# VPC Configuration
###################
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "The IPv4 CIDR block for the VPC"
  type        = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks to associate with the VPC (useful for EKS pod networking)"
  type        = list(string)
  default     = []
}

variable "availability_zones" {
  description = "List of availability zones to use for subnets"
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region for VPC endpoints"
  type        = string
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_network_address_usage_metrics" {
  description = "Enable network address usage metrics"
  type        = bool
  default     = false
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"
}

variable "enable_ipv6" {
  description = "Requests an Amazon-provided IPv6 CIDR block"
  type        = bool
  default     = false
}

###################
# Gateway Configuration
###################
variable "create_internet_gateway" {
  description = "Controls if an Internet Gateway should be created"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all private networks (cost savings)"
  type        = bool
  default     = false
}

###################
# Default Resource Management
###################
variable "manage_default_network_acl" {
  description = "Should be true to adopt and manage the default network ACL"
  type        = bool
  default     = true
}

variable "manage_default_security_group" {
  description = "Should be true to adopt and manage the default security group"
  type        = bool
  default     = true
}

variable "manage_default_route_table" {
  description = "Should be true to manage the default route table"
  type        = bool
  default     = true
}

###################
# VPC Flow Logs
###################
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_logs_iam_role_arn" {
  description = "ARN of IAM role for VPC Flow Logs"
  type        = string
  default     = ""
}

variable "flow_logs_destination_arn" {
  description = "ARN of CloudWatch Log Group or S3 Bucket for VPC Flow Logs"
  type        = string
  default     = ""
}

variable "flow_logs_destination_type" {
  description = "Type of flow log destination. Valid values: cloud-watch-logs, s3"
  type        = string
  default     = "cloud-watch-logs"
}

variable "flow_logs_traffic_type" {
  description = "Type of traffic to capture. Valid values: ACCEPT, REJECT, ALL"
  type        = string
  default     = "ALL"
}

variable "flow_logs_log_format" {
  description = "Custom format for VPC Flow Logs"
  type        = string
  default     = null
}

###################
# DHCP Options
###################
variable "create_dhcp_options" {
  description = "Should be true if you want to specify a DHCP options set"
  type        = bool
  default     = false
}

variable "dhcp_options_domain_name" {
  description = "Specifies DNS name for DHCP options set"
  type        = string
  default     = ""
}

variable "dhcp_options_domain_name_servers" {
  description = "Specify a list of DNS server addresses for DHCP options set"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_options_ntp_servers" {
  description = "Specify a list of NTP servers for DHCP options set"
  type        = list(string)
  default     = []
}

###################
# Public Subnets (External Incoming - for ALB, NAT Gateway)
###################
variable "external_incoming_subnet_cidrs" {
  description = "List of CIDR blocks for external incoming subnets (one per AZ) - for ALB, NAT Gateway"
  type        = list(string)
  default     = []
}

variable "external_incoming_subnet_tags" {
  description = "Additional tags for external incoming subnets"
  type        = map(string)
  default     = {}
}

###################
# Management Subnets (Bastion with Elastic IP)
###################
variable "management_subnet_cidrs" {
  description = "List of CIDR blocks for management subnets (one per AZ) - for bastion hosts"
  type        = list(string)
  default     = []
}

variable "management_subnet_tags" {
  description = "Additional tags for management subnets"
  type        = map(string)
  default     = {}
}

variable "map_public_ip_on_launch" {
  description = "Should be false - use Elastic IP for bastion instead of auto-assigned public IP"
  type        = bool
  default     = false
}

variable "enable_eks_elb_tag" {
  description = "Enable kubernetes.io/role/elb tag for external incoming subnets (for EKS external load balancers)"
  type        = bool
  default     = true
}

###################
# EKS Worker Node Subnets (Primary Workload - /21 for 2048 IPs per AZ)
###################
variable "eks_workers_subnet_cidrs" {
  description = "List of CIDR blocks for EKS worker node subnets (one per AZ) - use /21 for ~2000 IPs per AZ"
  type        = list(string)
  default     = []
}

variable "eks_workers_subnet_tags" {
  description = "Additional tags for EKS worker node subnets"
  type        = map(string)
  default     = {}
}

variable "enable_eks_internal_elb_tag" {
  description = "Enable kubernetes.io/role/internal-elb tag for EKS worker subnets (for EKS internal load balancers)"
  type        = bool
  default     = true
}

###################
# EKS Control Plane Subnets (Isolated)
###################
variable "eks_control_plane_subnet_cidrs" {
  description = "List of CIDR blocks for EKS control plane subnets (one per AZ)"
  type        = list(string)
  default     = []
}

variable "eks_control_plane_subnet_tags" {
  description = "Additional tags for EKS control plane subnets"
  type        = map(string)
  default     = {}
}

###################
# Database Subnets (Fully Isolated)
###################
variable "database_subnet_cidrs" {
  description = "List of CIDR blocks for database subnets (one per AZ) - fully isolated, no internet"
  type        = list(string)
  default     = []
}

variable "database_subnet_tags" {
  description = "Additional tags for database subnets"
  type        = map(string)
  default     = {}
}

###################
# Locker Database Subnets (PCI-DSS Compliant - Fully Isolated)
###################
variable "locker_database_subnet_cidrs" {
  description = "List of CIDR blocks for locker database subnets (one per AZ) - PCI-DSS compliant, fully isolated"
  type        = list(string)
  default     = []
}

variable "locker_database_subnet_tags" {
  description = "Additional tags for locker database subnets"
  type        = map(string)
  default     = {}
}

###################
# Locker Server Subnets (PCI-DSS Compliant - Fully Isolated)
###################
variable "locker_server_subnet_cidrs" {
  description = "List of CIDR blocks for locker server subnets (one per AZ) - PCI-DSS compliant, fully isolated"
  type        = list(string)
  default     = []
}

variable "locker_server_subnet_tags" {
  description = "Additional tags for locker server subnets"
  type        = map(string)
  default     = {}
}

###################
# ElastiCache Subnets (Fully Isolated)
###################
variable "elasticache_subnet_cidrs" {
  description = "List of CIDR blocks for ElastiCache subnets (one per AZ) - fully isolated, no internet"
  type        = list(string)
  default     = []
}

variable "elasticache_subnet_tags" {
  description = "Additional tags for ElastiCache subnets"
  type        = map(string)
  default     = {}
}

###################
# Data Stack Subnets (S3 Endpoint Only)
###################
variable "data_stack_subnet_cidrs" {
  description = "List of CIDR blocks for data stack subnets (one per AZ) - S3 endpoint access only"
  type        = list(string)
  default     = []
}

variable "data_stack_subnet_tags" {
  description = "Additional tags for data stack subnets"
  type        = map(string)
  default     = {}
}

###################
# Incoming Web Envoy Subnets (Private with NAT)
###################
variable "incoming_envoy_subnet_cidrs" {
  description = "List of CIDR blocks for incoming web envoy subnets (one per AZ) - private with NAT access"
  type        = list(string)
  default     = []
}

variable "incoming_envoy_subnet_tags" {
  description = "Additional tags for incoming envoy subnets"
  type        = map(string)
  default     = {}
}

###################
# Outgoing Proxy Subnets (Private with NAT)
###################
variable "outgoing_proxy_subnet_cidrs" {
  description = "List of CIDR blocks for outgoing proxy subnets (one per AZ) - private with NAT access"
  type        = list(string)
  default     = []
}

variable "outgoing_proxy_subnet_tags" {
  description = "Additional tags for outgoing proxy subnets"
  type        = map(string)
  default     = {}
}

###################
# Utils Subnets (Lambda, Elasticsearch - Private with NAT)
###################
variable "utils_subnet_cidrs" {
  description = "List of CIDR blocks for utils subnets (one per AZ) - Lambda, Elasticsearch, private with NAT"
  type        = list(string)
  default     = []
}

variable "utils_subnet_tags" {
  description = "Additional tags for utils subnets"
  type        = map(string)
  default     = {}
}

###################
# Lambda Subnets (Private with NAT and S3 endpoint access)
###################
variable "lambda_subnet_cidrs" {
  description = "List of CIDR blocks for Lambda subnets (one per AZ) - private with NAT and S3 endpoint"
  type        = list(string)
  default     = []
}

variable "lambda_subnet_tags" {
  description = "Additional tags for Lambda subnets"
  type        = map(string)
  default     = {}
}

###################
# Custom Subnet Groups
###################
variable "custom_subnet_groups" {
  description = "Map of custom subnet groups with their configurations"
  type = map(object({
    cidr_block        = string
    availability_zone = string
    tier              = string
    type              = string
    create_route_table = optional(bool, true)
    create_igw_route  = optional(bool, false)
    create_nat_route  = optional(bool, false)
    tags              = optional(map(string), {})
  }))
  default = {}
}

###################
# Network ACL
###################
variable "create_nacl" {
  description = "Controls if network ACL should be created for all subnets"
  type        = bool
  default     = true
}

###################
# VPC Endpoints
###################
variable "gateway_vpc_endpoints" {
  description = "List of gateway VPC endpoints to create (s3, dynamodb)"
  type        = list(string)
  default     = []
}

variable "interface_vpc_endpoints" {
  description = "List of interface VPC endpoints to create (ec2, ecr_api, ecr_dkr, logs, etc.)"
  type        = list(string)
  default     = []
}

variable "include_database_route_tables_in_gateway_endpoints" {
  description = "Whether to include database subnet route tables in gateway endpoints"
  type        = bool
  default     = false
}

variable "create_vpc_endpoint_security_group" {
  description = "Whether to create a security group for VPC endpoints"
  type        = bool
  default     = true
}

variable "vpc_endpoint_security_group_ids" {
  description = "List of security group IDs to attach to VPC endpoints (only used if create_vpc_endpoint_security_group is false)"
  type        = list(string)
  default     = []
}

variable "vpc_endpoint_private_dns_enabled" {
  description = "Whether to enable private DNS for VPC endpoints"
  type        = bool
  default     = true
}

###################
# Tags
###################
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
