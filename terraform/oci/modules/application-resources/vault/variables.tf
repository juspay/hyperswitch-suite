# vault - the OCI secret-delivery Vault + master key.

# -----------------------------------------------------------------------------
# Scope: this module owns a single DEFAULT OCI Vault and a single AES-256
# master key, for the ESO secret-delivery path. It creates NO identity policy,
# NO dynamic group, NO secrets, and NO workload mapping. Those belong with the
# oke-workload-identity (policy) / external-secrets-operator (grants + stores)
# modules and are deliberately excluded here.
# -----------------------------------------------------------------------------

variable "compartment_id" {
  description = <<-EOT
    OCID of the environment compartment that owns the Vault and its master key.
    This is also the compartment the consuming shared policy object is attached
    to, so keeping the Vault directly under it avoids a cross-compartment
    workload mapping.
  EOT
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID."
  }
}

variable "region" {
  description = "Region identifier (e.g. ap-mumbai-1). Tagged onto resources, and required by ESO's SecretStore via spec.provider.oracle.region."
  type        = string
  default     = null
}

variable "project_name" {
  description = "Project name, for naming and tags."
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment short name (dev, integ, sandbox, prod)."
  type        = string
}

variable "display_name" {
  description = "Display name of the OCI Vault. Defaults to '<project>-<environment>-eso-vault'."
  type        = string
  default     = null
}

variable "key_display_name" {
  description = "Display name of the master key. Defaults to '<project>-<environment>-eso-key'."
  type        = string
  default     = null
}

variable "enable_key_rotation" {
  description = "Enable automatic yearly key rotation. Rotation interval is bounded 60-365 days on OCI."
  type        = bool
  default     = true
}

variable "rotation_interval_in_days" {
  description = "Auto-rotation interval in days (60-365). Only used when enable_key_rotation is true."
  type        = number
  default     = 365
}

variable "restore_from_replica" {
  description = "Vault OCID to replicate/restore from for DR. Empty for the sandbox single-region vault."
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Freeform tags, merged over the module's own defaults."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "OCI defined tags, keyed 'namespace.key'."
  type        = map(string)
  default     = {}
}