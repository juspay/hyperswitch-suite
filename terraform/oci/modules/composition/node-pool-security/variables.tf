variable "compartment_id" {
  description = "OCID of the compartment in which to create the NSGs."
  type        = string
}

variable "vcn_id" {
  description = "OCID of the VCN in which to create the NSGs."
  type        = string
}

variable "environment" {
  description = "Environment identifier used verbatim in names and tags (prd for production)."
  type        = string
}

variable "project_name" {
  description = "Project name used in names and tags."
  type        = string
  default     = "hyperswitch"
}

variable "profiles" {
  description = "Named node-pool security profiles. Each profile owns a worker NSG and a pod NSG; an empty set creates none."
  type        = set(string)
  nullable    = false

  validation {
    condition     = alltrue([for profile in var.profiles : try(length(trimspace(profile)) > 0, false)])
    error_message = "Profile names must be non-null, non-empty strings containing at least one non-whitespace character."
  }
}

variable "freeform_tags" {
  description = "Additional freeform tags, merged over the module's default tags."
  type        = map(string)
  default     = {}
}
