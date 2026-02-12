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

variable "app_name" {
  description = "Application name (e.g., hyperswitch, control-centre)"
  type        = string
}

variable "role_name" {
  description = "Custom IAM role name. If null, auto-generated as {project}-{env}-{app}-role"
  type        = string
  default     = null
}

variable "role_description" {
  description = "Custom IAM role description"
  type        = string
  default     = null
}

variable "role_path" {
  description = "IAM role path"
  type        = string
  default     = "/"
}

variable "max_session_duration" {
  description = "Maximum session duration for the role (in seconds)"
  type        = number
  default     = 3600
}

variable "force_detach_policies" {
  description = "Whether to force detaching policies when destroying the role"
  type        = bool
  default     = true
}

variable "custom_trust_statements" {
  description = "Custom trust statements for maximum flexibility. Allows any valid IAM trust policy statement (Service, AWS, Federated, etc.). Highest priority in trust policy."
  type        = list(any)
  default     = []
}

variable "oidc_providers" {
  description = "OIDC provider trust for EKS service accounts (IRSA pattern). Supports multiple providers with multiple service accounts and different condition types (StringEquals, StringLike)."
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
  default = null
}

variable "assume_role_principals" {
  description = "Cross-account assume role trust. type: AWS for IAM roles, Federated for federated identities, Service for AWS services"
  type = list(object({
    type        = string
    identifiers = list(string)
  }))
  default = null
}

variable "aws_managed_policy_names" {
  description = "List of AWS managed policy names to attach (e.g., AmazonEC2ContainerRegistryReadOnly)"
  type        = list(string)
  default     = []
}

variable "customer_managed_policy_arns" {
  description = "List of customer managed policy ARNs to attach (typically from shared-policies)"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policies for role-specific permissions. Use sparingly - prefer managed policies for reusability."
  type        = map(string)
  default     = {}
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}