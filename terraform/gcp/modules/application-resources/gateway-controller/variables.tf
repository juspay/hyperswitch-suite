variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and labeling"
  type        = string
  default     = "hyperswitch"
}

variable "create_ssl_policy" {
  description = "Whether to create an SSL policy governing minimum TLS version/cipher suite for GKE-managed load balancers"
  type        = bool
  default     = true
}

variable "ssl_policy_profile" {
  description = "SSL policy profile: COMPATIBLE, MODERN, RESTRICTED, or CUSTOM"
  type        = string
  default     = "MODERN"
}

variable "ssl_policy_min_tls_version" {
  description = "Minimum TLS version: TLS_1_0, TLS_1_1, or TLS_1_2"
  type        = string
  default     = "TLS_1_2"
}

variable "create_service_account" {
  description = "Whether to create a Workload Identity-bound service account for BackendConfig/FrontendConfig automation"
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "Name of the GKE cluster. Required when create_service_account = true"
  type        = string
  default     = null
}

variable "cluster_location" {
  description = "Location (region or zone) of the GKE cluster. Required when create_service_account = true"
  type        = string
  default     = null
}

variable "k8s_namespace" {
  description = "Kubernetes namespace for the controller-adjacent service account"
  type        = string
  default     = "kube-system"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name for the controller-adjacent service account"
  type        = string
  default     = "gateway-controller"
}

variable "additional_project_roles" {
  description = "Additional project-level IAM roles to grant the controller-adjacent service account"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Additional labels to apply to created resources that support them"
  type        = map(string)
  default     = {}
}
