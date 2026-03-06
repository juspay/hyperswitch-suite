# =============================================================================
# EKS Kubernetes Resources Module - Variables (Wrapper)
# =============================================================================
# This wrapper passes all variables through to the implementation module.
# See ../backup/eks-kubernetes-resources/variables.tf for detailed descriptions.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Cluster Information
# These MUST be provided from the EKS cluster module outputs
# -----------------------------------------------------------------------------
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_id" {
  description = "The ID of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for the Kubernetes API server"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  type        = string
  sensitive   = true
}

variable "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider from the EKS cluster (for IRSA)"
  type        = string
}

# -----------------------------------------------------------------------------
# Environment Configuration
# -----------------------------------------------------------------------------
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
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
# Storage Class Configuration
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
# Cluster Autoscaler Configuration
# -----------------------------------------------------------------------------
variable "enable_cluster_autoscaler" {
  description = "Whether to deploy Cluster Autoscaler Kubernetes resources"
  type        = bool
  default     = false
}

variable "cluster_autoscaler_image" {
  description = "Full image URL for cluster autoscaler (ECR or public)"
  type        = string
  default     = null
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

# -----------------------------------------------------------------------------
# Cluster Autoscaler ECR Configuration (Optional)
# -----------------------------------------------------------------------------
variable "cluster_autoscaler_cluster_version" {
  description = "Kubernetes cluster version (used to determine autoscaler version if image_version not specified)"
  type        = string
  default     = null
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
  description = "Whether to use ECR for cluster autoscaler image. Set to false to use public registry directly."
  type        = bool
  default     = false
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

variable "cluster_autoscaler_ecr_repository_url" {
  description = "Existing ECR repository URL for cluster autoscaler (skips ECR creation if provided)"
  type        = string
  default     = null
}

variable "cluster_autoscaler_enable_image_sync" {
  description = "Whether to enable automatic image sync from public registry to ECR. Only applies when use_ecr=true and ecr_repository_url is not provided."
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region for ECR operations"
  type        = string
  default     = null
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
