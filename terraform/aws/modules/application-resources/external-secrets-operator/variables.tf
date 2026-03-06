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
  description = "Name of the External Secrets Operator IAM role. If null, defaults to {project}-{env}-external-secrets-role"
  type        = string
  default     = null
}

variable "role_description" {
  description = "Description for the External Secrets Operator IAM role"
  type        = string
  default     = "IAM role for External Secrets Operator to access AWS Secrets Manager"
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

variable "external_secrets_namespace" {
  description = "Kubernetes namespace where External Secrets Operator is deployed"
  type        = string
  default     = "external-secrets-operator"
}

variable "external_secrets_service_account" {
  description = "Service account name for External Secrets Operator"
  type        = string
  default     = "external-secrets-sa"
}

variable "oidc_audience" {
  description = "Audience for OIDC token validation"
  type        = string
  default     = "sts.amazonaws.com"
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
  #     { namespace = "external-secrets-operator", name = "external-secrets-sa" }
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
  description = "Additional policy ARNs to attach to the External Secrets Operator role"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
