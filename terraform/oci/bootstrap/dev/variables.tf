# =============================================================================
# General configuration
# =============================================================================
# Every default below is also set explicitly in terraform.tfvars. The defaults
# exist so this root is runnable, the tfvars exist so the real values are the
# reviewed, version-controlled ones.

variable "region" {
  description = "OCI region for the state bucket"
  type        = string
  default     = "ap-mumbai-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for naming and tagging"
  type        = string
  default     = "hyperswitch"
}

# The flat-compartment cut: everything in this programme's first pass lands
# directly in the "dev" compartment. identity-model.md's nested
# network/platform/data/apps compartment design is the eventual shape for scale,
# not what this proof-of-pipeline needs, and the state bucket would sit at the
# top of that tree anyway.
variable "compartment_id" {
  description = "OCID of the compartment the state bucket is created in"
  type        = string
}

# =============================================================================
# Bucket configuration
# =============================================================================

variable "state_bucket_name" {
  description = "Name of the Object Storage bucket for Terraform state"
  type        = string
  default     = "hyperswitch-dev-ap-mumbai-1-terraform-state"
}

variable "kms_key_id" {
  description = "OCID of an OCI Vault master key for the bucket (null uses the Oracle-managed key; encryption is on either way)"
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "Object lifecycle rules for the state bucket. Empty keeps all state history"
  type = list(object({
    name        = string
    action      = string
    time_amount = number
    time_unit   = string
    is_enabled  = bool
    target      = optional(string)
    object_name_filter = optional(object({
      inclusion_prefixes = optional(set(string))
      inclusion_patterns = optional(set(string))
      exclusion_patterns = optional(set(string))
    }))
  }))
  default = []
}

# =============================================================================
# Backend consumer access
# =============================================================================
# Null in dev today. The bootstrap is run by a human with tenancy-admin rights
# via the OCI CLI's SecurityToken session, which needs no policy. A CI group or
# a dynamic group of instance/workload principals gets one here once
# docs/multi-cloud-parity/oci/identity-model.md picks the principal type - that
# choice is that document's, not this root's, so nothing is guessed here.

variable "state_access_group_name" {
  description = "Existing IAM group name to grant state-bucket access to (null creates no group policy)"
  type        = string
  default     = null
}

variable "state_access_dynamic_group_name" {
  description = "Existing dynamic group name to grant state-bucket access to (null creates no dynamic-group policy)"
  type        = string
  default     = null
}

variable "backend_auth" {
  description = "auth method advertised in the generated backend configuration snippet (output only, applied to nothing)"
  type        = string
  default     = "SecurityToken"
}

# =============================================================================
# Tagging
# =============================================================================

variable "freeform_tags" {
  description = "Additional freeform tags for all resources"
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags for all resources. Requires the tag namespace to exist already"
  type        = map(string)
  default     = {}
}
