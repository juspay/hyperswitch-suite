variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "hyperswitch"
}

variable "role_name" {
  description = "Custom IAM role name"
  type        = string
  default     = "hyperswitch-encryption-service-sandbox-eso-role"
}

variable "oidc_provider_arn" {
  description = "Full OIDC provider ARN from EKS cluster. Found in EKS cluster details under OIDC provider"
  type        = string
  default     = "arn:aws:iam::XXXXXXXXXXXX:oidc-provider/oidc.eks.REGION.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXXXXXX"
}

variable "oidc_providers" {
  description = "Additional OIDC providers for EKS IRSA (optional)"
  type = map(object({
    provider_arn = string
    service_accounts = list(object({
      name            = string
      namespace       = string
      condition_type  = optional(string, "StringEquals")
      condition_key   = optional(string, null)
      condition_value = optional(list(string), null)
    }))
  }))
  default = {}
}

variable "customer_managed_policy_arns" {
  description = "List of customer managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "hyperswitch"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
