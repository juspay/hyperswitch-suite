# =============================================================================
# General configuration
# =============================================================================

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string

  validation {
    condition     = contains(["dev", "integ", "prod", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, integ, prod, sandbox"
  }
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "hyperswitch"
}

# OCI scopes resources by compartment. This replaces AWS's implicit "whatever
# account this provider is pointed at" and GCP's project_id - it is the single
# most important OCI-specific input on this module.
variable "compartment_id" {
  description = "OCID of the compartment the state bucket and its IAM policy are created in"
  type        = string

  validation {
    condition     = startswith(var.compartment_id, "ocid1.compartment.") || startswith(var.compartment_id, "ocid1.tenancy.")
    error_message = "compartment_id must be a compartment or tenancy OCID (ocid1.compartment... or ocid1.tenancy...)."
  }
}

# Passed through to outputs only. Unlike AWS, where the bucket's region is a
# computed attribute of the resource, an OCI bucket exposes no region attribute
# - the region is a property of the provider connection. The native `oci`
# backend still wants it as an explicit `region` argument, so the value has to
# be carried through rather than read back.
variable "region" {
  description = "OCI region identifier the bucket lives in (e.g. ap-mumbai-1)"
  type        = string
}

# =============================================================================
# Bucket configuration
# =============================================================================

variable "state_bucket_name" {
  description = "Name of the Object Storage bucket for Terraform state (unique within the tenancy namespace in this region)"
  type        = string
}

# Single optional field, where AWS needs both sse_algorithm and
# kms_master_key_id: OCI's KMS integration is present-or-absent, not a choice
# between algorithms, because AES-256 encryption is always on regardless.
variable "kms_key_id" {
  description = "OCID of an OCI Vault master encryption key for the bucket (null uses the Oracle-managed key; encryption is on either way)"
  type        = string
  default     = null
}

# Shape follows oci_objectstorage_object_lifecycle_policy's `rules` block
# (oracle/oci 9.0.0) rather than AWS's or GCP's inline rule shapes, since the
# resource is structured differently. Left empty by default: keep all state
# history, matching every AWS live instantiation of the sibling module.
variable "lifecycle_rules" {
  description = "Object lifecycle rules for the state bucket. Empty means no lifecycle policy resource is created and all state history is kept"
  type = list(object({
    name        = string
    action      = string # e.g. ARCHIVE, INFREQUENT_ACCESS, DELETE, ABORT
    time_amount = number
    time_unit   = string # DAYS or YEARS
    is_enabled  = bool
    target      = optional(string) # e.g. objects, previous-object-versions, multipart-uploads
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
# Both null by default. A tenancy admin running the bootstrap by hand needs no
# policy; these exist so a CI runner or an instance/workload principal can use
# the bucket afterwards. Which principal type is correct is an identity-model
# question that docs/multi-cloud-parity/oci/identity-model.md owns, not this
# module - hence two independent, optional levers rather than one baked-in
# assumption.

variable "state_access_group_name" {
  description = "Name of an existing IAM group to grant state-bucket access to (null creates no policy for a group)"
  type        = string
  default     = null
}

variable "state_access_dynamic_group_name" {
  description = "Name of an existing dynamic group (instance or workload principals) to grant state-bucket access to (null creates no policy for a dynamic group)"
  type        = string
  default     = null
}

# Advisory only: this value is not applied to any resource, it is substituted
# into the backend_config / backend_config_formatted outputs so the snippet a
# human copies into root.hcl is complete. Default matches the template in
# state-backend-decision.md section 4.
variable "backend_auth" {
  description = "The auth method to advertise in the generated backend configuration snippet"
  type        = string
  default     = "InstancePrincipal"

  validation {
    condition = contains([
      "APIKey",
      "InstancePrincipal",
      "ResourcePrincipal",
      "InstancePrincipalWithCerts",
      "SecurityToken",
      "OKEWorkloadIdentity",
    ], var.backend_auth)
    error_message = "backend_auth must be one of the six auth methods the oci backend supports: APIKey, InstancePrincipal, ResourcePrincipal, InstancePrincipalWithCerts, SecurityToken, OKEWorkloadIdentity."
  }
}

# =============================================================================
# Tagging
# =============================================================================
# Two namespaces where AWS and GCP have one. freeform_tags is the direct
# analogue of AWS `tags` / GCP `labels`. defined_tags needs a tag namespace to
# already exist in the tenancy, which cannot be assumed at bootstrap time, so it
# is optional and passed straight through.

variable "freeform_tags" {
  description = "Additional freeform tags applied to all resources, merged over the module's own tags"
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to all resources, as {\"namespace.key\" = \"value\"}. Requires the tag namespace to exist already"
  type        = map(string)
  default     = {}
}
