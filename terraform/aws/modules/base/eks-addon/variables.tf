variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "addon_name" {
  description = "Name of the EKS addon"
  type        = string
}

variable "addon_version" {
  description = "Version of the EKS addon"
  type        = string
  default     = null
}

variable "resolve_conflicts_on_create" {
  description = "How to resolve parameter value conflicts when creating the addon. Valid values: OVERWRITE, NONE, PRESERVE"
  type        = string
  default     = "OVERWRITE"

  validation {
    condition     = contains(["OVERWRITE", "NONE", "PRESERVE"], var.resolve_conflicts_on_create)
    error_message = "Resolve conflicts on create must be one of: OVERWRITE, NONE, PRESERVE"
  }
}

variable "resolve_conflicts_on_update" {
  description = "How to resolve parameter value conflicts when updating the addon. Valid values: OVERWRITE, NONE, PRESERVE"
  type        = string
  default     = "OVERWRITE"

  validation {
    condition     = contains(["OVERWRITE", "NONE", "PRESERVE"], var.resolve_conflicts_on_update)
    error_message = "Resolve conflicts on update must be one of: OVERWRITE, NONE, PRESERVE"
  }
}
variable "service_account_role_arn" {
  description = "ARN of the IAM role for the addon's service account"
  type        = string
  default     = null
}

variable "configuration_values" {
  description = "JSON string of configuration values for the addon"
  type        = string
  default     = null
}

variable "preserve" {
  description = "Whether to preserve the addon on cluster deletion"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
