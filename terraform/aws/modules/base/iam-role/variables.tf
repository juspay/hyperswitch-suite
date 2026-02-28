variable "create" {
  description = "Controls if resources should be created"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the IAM role"
  type        = string
}

variable "description" {
  description = "Description of the IAM role"
  type        = string
  default     = "Managed by Terraform"
}

variable "assume_role_policy" {
  description = "Assume role policy document (JSON)"
  type        = string
  default     = null
}

variable "service_identifiers" {
  description = "AWS service identifiers that can assume this role (e.g., ec2.amazonaws.com)"
  type        = list(string)
  default     = []
}

variable "managed_policy_arns" {
  description = "List of ARNs of managed policies to attach"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policies (name => policy document JSON)"
  type        = map(string)
  default     = {}
}

variable "create_instance_profile" {
  description = "Whether to create an instance profile"
  type        = bool
  default     = false
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds"
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "Max session duration must be between 3600 and 43200 seconds"
  }
}

variable "path" {
  description = "Path for the IAM role"
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Map of tags to apply to IAM resources"
  type        = map(string)
  default     = {}
}
