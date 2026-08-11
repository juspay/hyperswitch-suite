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

variable "region" {
  description = "Region for the dedicated Memorystore instance"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster hosting the ratelimiter"
  type        = string
}

variable "cluster_location" {
  description = "Location (region or zone) of the GKE cluster"
  type        = string
}

variable "k8s_namespace" {
  description = "Kubernetes namespace the ratelimiter runs in"
  type        = string
  default     = "hyperswitch"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name used by the ratelimiter"
  type        = string
  default     = "ratelimiter"
}

variable "additional_project_roles" {
  description = "Additional project-level IAM roles to grant the ratelimiter's service account"
  type        = list(string)
  default     = []
}

variable "create_redis" {
  description = "Whether to create a dedicated Memorystore instance for the ratelimiter"
  type        = bool
  default     = true
}

variable "authorized_network" {
  description = "Self-link/ID of the VPC network to peer the Memorystore instance to (requires Private Service Access)"
  type        = string
  default     = null
}

variable "redis_tier" {
  description = "Memorystore service tier"
  type        = string
  default     = "STANDARD_HA"
}

variable "redis_memory_size_gb" {
  description = "Memorystore memory size in GB"
  type        = number
  default     = 1
}

variable "create_firewall_rule" {
  description = "Whether to create the firewall rule allowing GKE pods to reach the Memorystore instance"
  type        = bool
  default     = true
}

variable "network_name" {
  description = "Name of the VPC network, required when create_firewall_rule = true"
  type        = string
  default     = null
}

variable "gke_pods_cidr" {
  description = "CIDR range of GKE pod IPs allowed to reach the Memorystore instance"
  type        = string
  default     = null
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
