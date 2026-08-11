# -----------------------------------------------------------------------------
# Required Cluster Information (from composition/gke outputs)
# -----------------------------------------------------------------------------
variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint (host, without scheme) for the Kubernetes API server"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Environment Configuration
# -----------------------------------------------------------------------------
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "labels" {
  description = "Labels to apply to created resources that support them"
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
  description = "Whether to create the default pd-balanced storage class"
  type        = bool
  default     = true
}

variable "default_storage_class_name" {
  description = "Name of the default storage class"
  type        = string
  default     = "pd-balanced"
}

variable "custom_storage_classes" {
  description = "Map of additional custom storage classes to create"
  type = map(object({
    storage_provisioner    = string
    volume_binding_mode    = optional(string, "Immediate")
    reclaim_policy         = optional(string, "Retain")
    allow_volume_expansion = optional(bool, false)
    parameters             = optional(map(string), {})
    annotations            = optional(map(string), {})
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Helm Deployment Configuration
# -----------------------------------------------------------------------------
variable "enable_helm_deployments" {
  description = "Enable Helm deployments managed by Terraform. Set to false if using ArgoCD instead"
  type        = bool
  default     = false
}

variable "create_registry_pull_secret" {
  description = "Whether to create a docker registry pull secret. Not normally needed for Artifact Registry, which authenticates via Workload Identity"
  type        = bool
  default     = false
}

variable "registry_pull_secret_server" {
  description = "Registry server for the optional pull secret"
  type        = string
  default     = null
}

variable "registry_pull_secret_username" {
  description = "Username for the optional pull secret"
  type        = string
  default     = null
}

variable "registry_pull_secret_password" {
  description = "Password/token for the optional pull secret"
  type        = string
  default     = null
  sensitive   = true
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
