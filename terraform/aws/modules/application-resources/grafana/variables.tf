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
  description = "Application name"
  type        = string
  default     = "grafana"
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

variable "oidc_providers" {
  description = "OIDC provider trust for EKS service accounts"
  type = map(object({
    provider_arn = string
    conditions = list(object({
      type   = string
      claim  = string
      values = list(string)
    }))
  }))
  default = null
}

variable "assume_role_principals" {
  description = "Cross-account assume role trust"
  type = list(object({
    type        = string
    identifiers = list(string)
  }))
  default = null
}

variable "aws_managed_policy_names" {
  description = "List of AWS managed policy names to attach"
  type        = list(string)
  default     = []
}

variable "customer_managed_policy_arns" {
  description = "List of customer managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policies for role-specific permissions"
  type        = map(string)
  default     = {}
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
