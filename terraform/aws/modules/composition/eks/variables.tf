# Core Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "cluster_name_version" {
  description = "Version identifier for the EKS cluster name"
  type        = string
  default     = "v1"
}

# EKS Configuration
variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpn_cidr_blocks" {
  description = "CIDR blocks for VPN access to EKS cluster (e.g., ['10.8.0.0/16'])"
  type        = list(string)
  default     = []
}

variable "cluster_access_entries" {
  description = "Map of IAM principals to grant access to the EKS cluster"
  type        = any
  default     = {}
}

variable "argocd_assume_role_principal_arn" {
  description = "ARN of the ArgoCD IAM role that can assume the EKS cluster role"
  type        = string
  default     = null
}

# Networking
variable "vpc_id" {
  description = "VPC ID where the cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "Subnet IDs for EKS control plane (if different from subnet_ids)"
  type        = list(string)
  default     = null
}

# Node Groups
variable "node_groups" {
  description = "EKS managed node groups configuration"
  type        = any
  default     = {}
}

# KMS Configuration
variable "kms_key_administrators" {
  description = "A list of IAM ARNs for key administrators. If no value is provided, the current caller identity is used to ensure at least one key admin is available"
  type        = list(string)
  default     = []
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}