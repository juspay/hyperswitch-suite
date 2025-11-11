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

variable "resolve_conflicts" {
  description = "How to resolve parameter value conflicts. Valid values: OVERWRITE, NONE, PRESERVE"
  type        = string
  default     = "OVERWRITE"
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
