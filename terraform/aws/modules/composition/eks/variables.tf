# =============================================================================
# EKS Composition Module - Variables
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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Cluster IAM Role Configuration (Required from Live Layer)
# -----------------------------------------------------------------------------
variable "create_cluster_iam_role" {
  description = "Whether to create a custom IAM role for the EKS cluster. Set to false if using existing role."
  type        = bool
  default     = true
}

variable "cluster_iam_role_arn" {
  description = "Existing IAM role ARN for EKS cluster (required if create_cluster_iam_role = false)"
  type        = string
  default     = null
}

variable "cluster_iam_role_name" {
  description = "Custom name for the EKS cluster IAM role (auto-generated if null)"
  type        = string
  default     = null
}

variable "cluster_iam_role_assume_role_policy" {
  description = "Assume role policy JSON for EKS cluster IAM role. MUST be provided from live layer."
  type        = string
}

variable "cluster_iam_role_policies" {
  description = "Map of IAM policy ARNs to attach to the cluster IAM role"
  type        = map(string)
  default     = {}
}

variable "cluster_custom_policy_json" {
  description = "Custom IAM policy JSON for cluster role (additional permissions). Set to null to skip."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Node Group IAM Role Configuration (Required from Live Layer)
# -----------------------------------------------------------------------------
variable "create_node_group_iam_role" {
  description = "Whether to create a custom IAM role for node groups. Set to false if using existing role."
  type        = bool
  default     = true
}

variable "node_group_iam_role_arn" {
  description = "Existing IAM role ARN for node groups (required if create_node_group_iam_role = false)"
  type        = string
  default     = null
}

variable "node_group_iam_role_name" {
  description = "Custom name for the node group IAM role (auto-generated if null)"
  type        = string
  default     = null
}

variable "node_group_iam_role_assume_role_policy" {
  description = "Assume role policy JSON for node group IAM role. MUST be provided from live layer."
  type        = string
}

variable "node_group_iam_role_policies" {
  description = "Map of IAM policy ARNs to attach to the node group IAM role"
  type        = map(string)
  default     = {}
}

variable "node_group_custom_policy_json" {
  description = "Custom IAM policy JSON for node group (e.g., observability). Set to null to skip."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Cross-Account Role Configuration (Required from Live Layer)
# For ArgoCD, Atlantis, CI/CD from management cluster
# -----------------------------------------------------------------------------
variable "create_cross_account_role" {
  description = "Whether to create IAM role for cross-account access"
  type        = bool
  default     = false
}

variable "cross_account_role_name" {
  description = "Custom name for cross-account role (auto-generated if null)"
  type        = string
  default     = null
}

variable "cross_account_assume_role_policy" {
  description = "Assume role policy JSON for cross-account role. MUST be provided if create_cross_account_role = true."
  type        = string
  default     = null
}

variable "cross_account_policy_json" {
  description = "IAM policy JSON for cross-account role. MUST be provided if create_cross_account_role = true."
  type        = string
  default     = null
}

variable "cross_account_policy_arns" {
  description = "List of IAM policy ARNs to attach to cross-account role (alternative to policy JSON)"
  type        = list(string)
  default     = []
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

# -----------------------------------------------------------------------------
# Node Groups
# -----------------------------------------------------------------------------
variable "node_groups" {
  description = "EKS managed node groups configuration"
  type        = any
  default     = {}
}

# -----------------------------------------------------------------------------
# KMS Configuration
# -----------------------------------------------------------------------------
variable "kms_key_administrators" {
  description = "A list of IAM ARNs for key administrators. If no value is provided, the current caller identity is used to ensure at least one key admin is available"
  type        = list(string)
  default     = []
}


# -----------------------------------------------------------------------------
# Region Variable
# -----------------------------------------------------------------------------
variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

# -----------------------------------------------------------------------------
# EKS Addons Configuration
# -----------------------------------------------------------------------------
variable "eks_addons" {
  description = "EKS addons configuration - map keyed by addon name"
  type = map(object({
    addon_version        = string
    service_account_role = optional(string) # "cluster_autoscaler", "ebs_csi", or full ARN
  }))
  default = {}
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
  description = "SSH key pair name. Used directly if create_ssh_key=false. Used as name for new key if create_ssh_key=true. Auto-generated if null."
  type        = string
  default     = null
}

variable "ssh_public_key" {
  description = "Public key material for creating SSH key pair. If not provided when create_ssh_key=true, a new key will be auto-generated and stored in SSM."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Default Metadata Options
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# Launch Template Configuration
# -----------------------------------------------------------------------------
variable "default_ami_id" {
  description = "Default AMI ID for EKS nodes. If null, the latest EKS-optimized AMI will be used via data source"
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

variable "custom_userdata_template_path" {
  description = "Path to custom user data template file. Uses default bootstrap template if null"
  type        = string
  default     = null
}
