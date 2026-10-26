# ============================================================================
# Environment & Project Configuration
# ============================================================================
variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., sandbox, integ, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster the Cluster Autoscaler scales"
  type        = string
}

# ============================================================================
# Service Account Configuration
# ============================================================================
variable "namespace" {
  description = "Namespace the Cluster Autoscaler is deployed into"
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Name of the Cluster Autoscaler service account the IAM role is scoped to. Must match the service account created by the Helm chart deployed via ArgoCD."
  type        = string
  default     = "cluster-autoscaler"
}

# ============================================================================
# IAM Role Configuration
# ============================================================================
variable "role_name" {
  description = "Name of the IAM role. Defaults to <environment>-<project_name>-cluster-autoscaler when null."
  type        = string
  default     = null
}

variable "role_description" {
  description = "Description of the IAM role"
  type        = string
  default     = "IAM role for the Cluster Autoscaler (IRSA)"
}

variable "role_path" {
  description = "Path for the IAM role and policy"
  type        = string
  default     = "/"
}

variable "max_session_duration" {
  description = "Maximum session duration (in seconds) for the IAM role"
  type        = number
  default     = 3600
}

variable "additional_policy_arns" {
  description = "Additional IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

# ============================================================================
# Tags
# ============================================================================
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
