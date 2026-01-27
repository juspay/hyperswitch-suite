variable "policies" {
  description = "Map of customer managed IAM policies to create"
  type = map(object({
    name        = string
    description = optional(string, "")
    path        = optional(string, "/")
    policy      = string
    tags        = optional(map(string), {})
  }))
  default = {}
}

variable "roles" {
  description = "Map of IAM roles to create"
  type = map(object({
    role_name = string

    # Trust policy configuration
    trust_policy = object({
      oidc_providers = optional(map(object({
        provider_arn               = string
        namespace_service_accounts = list(string)
      })), {})

      assume_role_principals = optional(list(object({
        type        = string
        identifiers = list(string)
      })), [])
    })

    # Permissions - can reference by name or provide ARN
    managed_policy_names = optional(list(string), [])
    managed_policy_arns  = optional(list(string), [])
    inline_policies      = optional(map(string), {})

    # Optional role configuration
    description          = optional(string, "")
    path                 = optional(string, "/")
    max_session_duration = optional(number, 3600)

    # Tags
    tags = optional(map(string), {})
  }))
}

variable "eks_oidc_provider_arns" {
  description = "List of EKS OIDC provider ARNs"
  type        = list(string)
}

variable "tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default     = {}
}