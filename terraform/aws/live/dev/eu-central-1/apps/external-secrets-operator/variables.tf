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
  description = "Name of the External Secrets Operator IAM role"
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
