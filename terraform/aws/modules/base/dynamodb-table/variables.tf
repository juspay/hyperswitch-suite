variable "create" {
  description = "Controls if resources should be created"
  type        = bool
  default     = true
}

variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "billing_mode" {
  description = "Billing mode for the table (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.billing_mode)
    error_message = "Billing mode must be either PROVISIONED or PAY_PER_REQUEST"
  }
}

variable "hash_key" {
  description = "Attribute to use as the hash (partition) key"
  type        = string
}

variable "range_key" {
  description = "Attribute to use as the range (sort) key"
  type        = string
  default     = null
}

variable "attributes" {
  description = "List of attribute definitions"
  type = list(object({
    name = string
    type = string  # S (string), N (number), or B (binary)
  }))

  validation {
    condition = alltrue([
      for attr in var.attributes : contains(["S", "N", "B"], attr.type)
    ])
    error_message = "Attribute types must be one of: S (string), N (number), or B (binary)"
  }
}

variable "read_capacity" {
  description = "Read capacity units (only used with PROVISIONED billing mode)"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Write capacity units (only used with PROVISIONED billing mode)"
  type        = number
  default     = 5
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for the table"
  type        = bool
  default     = false
}

variable "enable_encryption" {
  description = "Enable server-side encryption"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption (null uses AWS managed key)"
  type        = string
  default     = null
}

variable "ttl_enabled" {
  description = "Enable TTL for the table"
  type        = bool
  default     = false
}

variable "ttl_attribute_name" {
  description = "Name of the attribute to use for TTL"
  type        = string
  default     = null
}

variable "global_secondary_indexes" {
  description = "List of global secondary indexes"
  type = list(object({
    name            = string
    hash_key        = string
    range_key       = optional(string, null)
    projection_type = string  # ALL, KEYS_ONLY, or INCLUDE
    read_capacity   = optional(number, 5)
    write_capacity  = optional(number, 5)
  }))
  default = []
}

variable "local_secondary_indexes" {
  description = "List of local secondary indexes"
  type = list(object({
    name            = string
    range_key       = string
    projection_type = string  # ALL, KEYS_ONLY, or INCLUDE
  }))
  default = []
}

variable "tags" {
  description = "Map of tags to apply to the table"
  type        = map(string)
  default     = {}
}
