variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string

  validation {
    condition     = contains(["dev", "integ", "prod", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, integ, prod, sandbox"
  }
}

variable "project_name" {
  description = "Project name for labeling and naming resources"
  type        = string
  default     = "hyperswitch"
}

variable "project_id" {
  description = "GCP project ID where the state bucket is created"
  type        = string
}

variable "location" {
  description = "GCS bucket location (region or multi-region, e.g. europe-west1 or EU)"
  type        = string
}

# Bucket Configuration

variable "state_bucket_name" {
  description = "Name of the GCS bucket for Terraform state (must be globally unique)"
  type        = string
}

variable "storage_class" {
  description = "Storage class for the state bucket"
  type        = string
  default     = "STANDARD"
}

variable "allow_destroy" {
  description = "Allow destruction of the bucket even if it contains objects (should be false for prod)"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "Self link of the KMS CryptoKey used to encrypt the bucket (null uses Google-managed encryption)"
  type        = string
  default     = null
}

variable "retention_period_seconds" {
  description = "Minimum retention period (seconds) objects must be retained. Null disables the retention policy"
  type        = number
  default     = null
}

variable "retention_policy_locked" {
  description = "Whether the retention policy is locked (irreversible). Only used when retention_period_seconds is set"
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the state bucket"
  type = list(object({
    action = object({
      type          = string
      storage_class = optional(string)
    })
    condition = object({
      age                   = optional(number)
      created_before        = optional(string)
      with_state            = optional(string)
      num_newer_versions    = optional(number)
      matches_storage_class = optional(string)
    })
  }))
  default = [] # No lifecycle rules by default - keep all state history
}

# Labeling

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
