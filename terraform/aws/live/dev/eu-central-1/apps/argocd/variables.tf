# ============================================================================
# Environment & Project Configuration
# ============================================================================
variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "hyperswitch"
}

# ============================================================================
# IAM Role Configuration
# ============================================================================
variable "role_name" {
  description = "Name of the ArgoCD management IAM role"
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

# ============================================================================
# OIDC and Service Account Configuration
# ============================================================================

variable "cluster_service_accounts" {
  description = "Map of cluster names to service accounts that can assume this role"
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

variable "oidc_provider_arns" {
  description = "Map of cluster names to their OIDC provider ARNs"
  type        = map(string)
  default     = {}
}

variable "additional_assume_role_statements" {
  description = "Additional IAM policy statements to add to the role's assume role policy"
  type        = list(any)
  default     = []
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
