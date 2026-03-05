# =============================================================================
# EKS Cluster - Variables (Pass-through to Module)
# =============================================================================
# NOTE: JSON policies (assume role policies, custom policies) are defined
# in main.tf locals because jsonencode() cannot be used in tfvars files.
# =============================================================================

# -----------------------------------------------------------------------------
# Core Variables
# -----------------------------------------------------------------------------
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

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------
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
  description = "CIDR blocks for VPN access to EKS cluster"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Cluster Access
# -----------------------------------------------------------------------------
variable "cluster_access_entries" {
  description = "Map of IAM principals to grant access to the EKS cluster"
  type        = any
  default     = {}
}

variable "kms_key_administrators" {
  description = "A list of IAM ARNs for key administrators"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Cluster IAM Role Configuration
# NOTE: Assume role policy is defined in main.tf locals
# -----------------------------------------------------------------------------
variable "create_cluster_iam_role" {
  description = "Whether to create a custom IAM role for the EKS cluster"
  type        = bool
  default     = true
}

variable "cluster_iam_role_arn" {
  description = "Existing IAM role ARN for EKS cluster (required if create_cluster_iam_role = false)"
  type        = string
  default     = null
}

variable "cluster_iam_role_name" {
  description = "Custom name for the EKS cluster IAM role"
  type        = string
  default     = null
}

variable "cluster_iam_role_policies" {
  description = "Map of IAM policy ARNs to attach to the cluster IAM role"
  type        = map(string)
  default     = {}
}

variable "cluster_custom_policy_json" {
  description = "Custom IAM policy JSON for cluster role (set to null to skip)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Node Group IAM Role Configuration
# NOTE: Assume role policy and custom policy are defined in main.tf locals
# -----------------------------------------------------------------------------
variable "create_node_group_iam_role" {
  description = "Whether to create a custom IAM role for node groups"
  type        = bool
  default     = true
}

variable "node_group_iam_role_arn" {
  description = "Existing IAM role ARN for node groups"
  type        = string
  default     = null
}

variable "node_group_iam_role_name" {
  description = "Custom name for the node group IAM role"
  type        = string
  default     = null
}

variable "node_group_iam_role_policies" {
  description = "Map of IAM policy ARNs to attach to the node group IAM role"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Cross-Account Role Configuration
# NOTE: Assume role policy and policy JSON are defined in main.tf locals
# -----------------------------------------------------------------------------
variable "create_cross_account_role" {
  description = "Whether to create IAM role for cross-account access"
  type        = bool
  default     = false
}

variable "cross_account_role_name" {
  description = "Custom name for cross-account role"
  type        = string
  default     = null
}

variable "cross_account_policy_arns" {
  description = "List of IAM policy ARNs to attach to cross-account role"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Node Groups
# -----------------------------------------------------------------------------
variable "node_groups" {
  description = "EKS managed node groups configuration"
  type        = any
  default     = {}
}

# -----------------------------------------------------------------------------
# Launch Template Configuration
# -----------------------------------------------------------------------------
variable "default_ami_id" {
  description = "Default AMI ID for EKS nodes"
  type        = string
  default     = null
}

variable "default_block_device_mappings" {
  description = "Default block device mappings for launch templates"
  type = list(object({
    device_name           = string
    volume_size           = number
    volume_type           = string
    delete_on_termination = bool
    encrypted             = bool
    kms_key_id            = optional(string)
    iops                  = optional(number)
    throughput            = optional(number)
  }))
  default = [
    {
      device_name           = "/dev/xvda"
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = null
      iops                  = null
      throughput            = null
    }
  ]
}

variable "default_metadata_options" {
  description = "Default metadata options for launch templates (IMDSv2)"
  type = object({
    http_endpoint               = optional(string, "enabled")
    http_tokens                 = optional(string, "required")
    http_put_response_hop_limit = optional(number, 2)
    instance_metadata_tags      = optional(string, "enabled")
  })
  default = {}
}

variable "custom_userdata_template_path" {
  description = "Path to custom user data template file"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# SSH Key Configuration
# -----------------------------------------------------------------------------
variable "create_ssh_key" {
  description = "Whether to create a new SSH key pair for node groups"
  type        = bool
  default     = false
}

variable "ssh_key_name" {
  description = "SSH key pair name"
  type        = string
  default     = null
}

variable "ssh_public_key" {
  description = "Public key material for creating SSH key pair"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# EKS Addons Configuration
# -----------------------------------------------------------------------------
variable "eks_addons" {
  description = "EKS addons configuration - map keyed by addon name"
  type = map(object({
    addon_version        = string
    service_account_role = optional(string)
  }))
  default = {}
}
