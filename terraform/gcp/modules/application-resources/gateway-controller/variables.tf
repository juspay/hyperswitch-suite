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

# SSL policy

variable "create_ssl_policy" {
  description = "Whether to create an SSL policy governing the minimum TLS version and cipher profile for the load balancers GKE creates. Attach it from a FrontendConfig's spec.sslPolicy using the ssl_policy_name output"
  type        = bool
  default     = true
}

variable "ssl_policy_profile" {
  description = "SSL policy profile: COMPATIBLE, MODERN, RESTRICTED, or CUSTOM. CUSTOM requires ssl_policy_custom_features"
  type        = string
  default     = "MODERN"

  validation {
    condition     = contains(["COMPATIBLE", "MODERN", "RESTRICTED", "CUSTOM"], var.ssl_policy_profile)
    error_message = "ssl_policy_profile must be one of COMPATIBLE, MODERN, RESTRICTED, CUSTOM."
  }
}

variable "ssl_policy_min_tls_version" {
  description = "Minimum TLS version: TLS_1_0, TLS_1_1, or TLS_1_2"
  type        = string
  default     = "TLS_1_2"

  validation {
    condition     = contains(["TLS_1_0", "TLS_1_1", "TLS_1_2"], var.ssl_policy_min_tls_version)
    error_message = "ssl_policy_min_tls_version must be one of TLS_1_0, TLS_1_1, TLS_1_2."
  }
}

variable "ssl_policy_custom_features" {
  description = "Explicit cipher suite list. Only read when ssl_policy_profile = CUSTOM; ignored (and not sent to the API) otherwise"
  type        = list(string)
  default     = []
}

# Optional controller-adjacent service account. Off by default: GKE's own
# Ingress/Gateway controllers need no identity of yours.

variable "create_service_account" {
  description = "Whether to create a Workload Identity-bound service account for BackendConfig/FrontendConfig automation. The GKE Ingress/Gateway controllers themselves do NOT need this"
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

variable "cluster_endpoint" {
  description = "GKE cluster API server endpoint (bare host:port or IP, no scheme). Required when create_service_account = true - configures this module's kubernetes provider"
  type        = string
  default     = null
}

variable "cluster_ca_certificate" {
  description = "GKE cluster CA certificate, base64-encoded. Required when create_service_account = true - configures this module's kubernetes provider"
  type        = string
  default     = null
  sensitive   = true
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

variable "use_existing_k8s_sa" {
  description = "Whether the Kubernetes service account already exists (skip creating it and bind Workload Identity to it instead)"
  type        = bool
  default     = false
}

variable "annotate_k8s_sa" {
  description = "Whether to annotate the Kubernetes service account with the Google service account email"
  type        = bool
  default     = true
}

variable "additional_project_roles" {
  description = "Project-level IAM roles to grant the controller-adjacent service account"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Additional labels to apply to created resources that support them"
  type        = map(string)
  default     = {}
}
