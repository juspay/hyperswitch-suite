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

# -----------------------------------------------------------------------------
# Cluster Autoscaler Configuration
# -----------------------------------------------------------------------------
variable "enable_cluster_autoscaler" {
  description = "Whether to deploy Cluster Autoscaler"
  type        = bool
  default     = false
}

variable "cluster_autoscaler_image_version" {
  description = "Cluster Autoscaler image version tag (e.g., 'v1.35.0'). Auto-detected from cluster version if null"
  type        = string
  default     = null
}

variable "cluster_autoscaler_source_registry" {
  description = "Container registry for cluster autoscaler image source"
  type        = string
  default     = "registry.k8s.io"
}

variable "cluster_autoscaler_architectures" {
  description = "List of CPU architectures for multi-arch image sync (e.g., ['amd64', 'arm64'])"
  type        = list(string)
  default     = ["amd64", "arm64"]
}

variable "cluster_autoscaler_use_ecr" {
  description = "Whether to use ECR for cluster autoscaler image (required for private VPCs)"
  type        = bool
  default     = true
}

variable "cluster_autoscaler_ecr_repo_name" {
  description = "Custom ECR repository name for cluster autoscaler (auto-generated if null)"
  type        = string
  default     = null
}

variable "cluster_autoscaler_ecr_max_images" {
  description = "Maximum number of images to keep in ECR lifecycle policy"
  type        = number
  default     = 5
}

variable "cluster_autoscaler_service_account_name" {
  description = "Service account name for cluster autoscaler"
  type        = string
  default     = null
}

variable "cluster_autoscaler_resources" {
  description = "Resource requests and limits for cluster autoscaler"
  type = object({
    requests_cpu    = optional(string, "100m")
    requests_memory = optional(string, "600Mi")
    limits_cpu      = optional(string, "100m")
    limits_memory   = optional(string, "600Mi")
  })
  default = {}
}

variable "cluster_autoscaler_log_level" {
  description = "Log level for cluster autoscaler (1-5)"
  type        = number
  default     = 4
}

variable "cluster_autoscaler_expander" {
  description = "Expander strategy for cluster autoscaler (least-waste, most-pods, priority, random)"
  type        = string
  default     = "least-waste"
}

variable "cluster_autoscaler_extra_args" {
  description = "Additional command line arguments for cluster autoscaler"
  type        = list(string)
  default     = []
}

variable "cluster_autoscaler_node_selector" {
  description = "Node selector for scheduling cluster autoscaler pod"
  type        = map(string)
  default     = {}
}

variable "cluster_autoscaler_tolerations" {
  description = "Tolerations for scheduling cluster autoscaler pod"
  type = list(object({
    key      = string
    operator = string
    value    = optional(string)
    effect   = string
  }))
  default = []
}

variable "cluster_autoscaler_pod_annotations" {
  description = "Additional pod annotations for cluster autoscaler"
  type        = map(string)
  default     = {}
}

variable "cluster_autoscaler_ecr_repository_url" {
  description = "Existing ECR repository URL for cluster autoscaler (skips ECR creation if provided)"
  type        = string
  default     = null
}

variable "cluster_autoscaler_skip_image_sync" {
  description = "Skip automatic image sync to ECR (set true if you manage image sync separately)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# RBAC Configuration
# -----------------------------------------------------------------------------
variable "create_default_rbac_roles" {
  description = "Whether to create default RBAC roles (developer, readonly, cicd)"
  type        = bool
  default     = true
}

variable "custom_rbac_roles" {
  description = "Additional custom RBAC roles to create"
  type = map(object({
    rules = list(object({
      api_groups     = list(string)
      resources      = list(string)
      verbs          = list(string)
      resource_names = optional(list(string), [])
    }))
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Kubernetes Resources Configuration
# -----------------------------------------------------------------------------
variable "create_default_storage_class" {
  description = "Whether to create default gp3 storage class for EBS volumes"
  type        = bool
  default     = true
}

variable "default_storage_class_name" {
  description = "Name of the default storage class"
  type        = string
  default     = "ebs-gp3"
}

# -----------------------------------------------------------------------------
# Helm Deployment Configuration
# -----------------------------------------------------------------------------
variable "enable_helm_deployments" {
  description = "Enable Helm deployments managed by Terraform. Set to false if using ArgoCD from another cluster"
  type        = bool
  default     = false
}

variable "create_ecr_registry_secret" {
  description = "Whether to create ECR registry secret for pulling images"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Hyperswitch Helm Configuration
# -----------------------------------------------------------------------------
variable "hyperswitch_namespace" {
  description = "Kubernetes namespace for Hyperswitch deployment"
  type        = string
  default     = "hyperswitch"
}

variable "hyperswitch_release_name" {
  description = "Helm release name for Hyperswitch stack"
  type        = string
  default     = "hyperswitch-stack"
}

variable "hyperswitch_helm_repository" {
  description = "Helm repository URL for Hyperswitch chart"
  type        = string
  default     = "https://juspay.github.io/hyperswitch-helm"
}

variable "hyperswitch_helm_chart" {
  description = "Helm chart name for Hyperswitch"
  type        = string
  default     = "hyperswitch-stack"
}

variable "hyperswitch_chart_version" {
  description = "Helm chart version for Hyperswitch (null for latest)"
  type        = string
  default     = null
}

variable "hyperswitch_values_file" {
  description = "Path to custom Helm values file for Hyperswitch (null for defaults)"
  type        = string
  default     = null
}

variable "hyperswitch_helm_timeout" {
  description = "Timeout in seconds for Helm deployment"
  type        = number
  default     = 900
}

# -----------------------------------------------------------------------------
# Additional Cluster Autoscaler Variables
# -----------------------------------------------------------------------------
variable "cluster_autoscaler_command" {
  description = "Full command override for cluster autoscaler (replaces default command if provided)"
  type        = list(string)
  default     = null
}

variable "cluster_autoscaler_command_extra_args" {
  description = "Additional command line arguments appended to default command"
  type        = list(string)
  default     = []
}

variable "cluster_autoscaler_skip_local_storage" {
  description = "Skip nodes with local storage"
  type        = bool
  default     = false
}

variable "cluster_autoscaler_skip_system_pods" {
  description = "Skip nodes with system pods"
  type        = bool
  default     = false
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
# ArgoCD Cross-Account Role
# -----------------------------------------------------------------------------
variable "create_argocd_cross_account_role" {
  description = "Whether to create IAM role for ArgoCD cross-account access"
  type        = bool
  default     = false
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
# Node Group IAM Configuration
# -----------------------------------------------------------------------------
variable "node_group_iam_role_name" {
  description = "Custom name for node group IAM role (auto-generated if null)"
  type        = string
  default     = null
}

variable "node_group_custom_policy" {
  description = "Custom observability policy - set to 'default' for built-in policy, null to skip, or provide JSON"
  type        = string
  default     = "default"
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

# -----------------------------------------------------------------------------
# Node Group IAM Policies
# -----------------------------------------------------------------------------
variable "node_group_iam_policies" {
  description = "Map of IAM policy ARNs to attach to the node group IAM role"
  type        = map(string)
  default = {
    amazon_eks_worker_node             = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    amazon_eks_cni_policy              = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    amazon_ec2_container_registry_read = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    amazon_ssm_managed_instance        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}