# ============================================================================
# Environment & Project Configuration
# ============================================================================

variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
}

# ============================================================================
# IAM Role Configuration
# ============================================================================

variable "role_name" {
  description = "Name of the ArgoCD management IAM role. If null, defaults to {project}-{env}-argocd-management-role"
  type        = string
  default     = null
}

variable "role_description" {
  description = "Description for the ArgoCD management IAM role"
  type        = string
  default     = "IAM role for ArgoCD to manage cross-account deployments"
}

variable "role_path" {
  description = "Path for the IAM role"
  type        = string
  default     = "/"
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds for the role"
  type        = number
  default     = 3600
}

# ============================================================================
# Trust Policy Configuration
# ============================================================================

variable "aws_account_id" {
  description = "AWS Account ID where the role is created"
  type        = string
}

variable "argocd_namespace" {
  description = "Kubernetes namespace where ArgoCD is deployed"
  type        = string
  default     = "argocd"
}

variable "argocd_service_accounts" {
  description = "List of ArgoCD service accounts that can assume this role"
  type        = list(string)
  default = [
    "argocd-application-controller",
    "argocd-applicationset-controller",
    "argocd-server"
  ]
}

variable "oidc_audience" {
  description = "Audience for OIDC token validation"
  type        = string
  default     = "sts.amazonaws.com"
}

# ============================================================================
# Cross-Account Role Configuration
# ============================================================================

variable "cross_account_roles" {
  description = "List of cross-account role ARNs that ArgoCD can assume"
  type        = list(string)
  default     = []
}

variable "create_assume_role_policy" {
  description = "Whether to create and attach the assume role policy for cross-account access"
  type        = bool
  default     = true
}

# ============================================================================
# OIDC and Service Account Configuration
# ============================================================================

variable "cluster_service_accounts" {
  description = "Map of cluster names to service accounts that can assume this role. Each service account must have 'namespace' and 'name' attributes."
  type = map(list(object({
    namespace = string
    name      = string
  })))
  default = {}

  # Example:
  # {
  #   "dev-eks-cluster" = [
  #     { namespace = "argocd", name = "argocd-application-controller" },
  #     { namespace = "argocd", name = "argocd-server" }
  #   ]
  # }
}


variable "additional_assume_role_statements" {
  description = "Additional IAM policy statements to add to the role's assume role policy"
  type        = list(any)
  default     = []
}

# ============================================================================
# Additional Configuration
# ============================================================================

variable "additional_policy_arns" {
  description = "Additional policy ARNs to attach to the ArgoCD role"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
