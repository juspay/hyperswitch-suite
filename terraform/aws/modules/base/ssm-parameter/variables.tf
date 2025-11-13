variable "name" {
  description = "Name of the SSM parameter"
  type        = string
}

variable "description" {
  description = "Description of the SSM parameter"
  type        = string
  default     = ""
}

variable "type" {
  description = "Type of the parameter. Valid values: String, StringList, SecureString"
  type        = string
  default     = "SecureString"

  validation {
    condition     = contains(["String", "StringList", "SecureString"], var.type)
    error_message = "Type must be one of: String, StringList, SecureString"
  }
}

variable "value" {
  description = "Value of the parameter"
  type        = string
  sensitive   = true
}

variable "tier" {
  description = "Parameter tier. Valid values: Standard, Advanced, Intelligent-Tiering"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Advanced", "Intelligent-Tiering"], var.tier)
    error_message = "Tier must be one of: Standard, Advanced, Intelligent-Tiering"
  }
}

variable "key_id" {
  description = "KMS key ID for encrypting SecureString parameters"
  type        = string
  default     = null
}

variable "overwrite" {
  description = "Overwrite an existing parameter"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
