# ==============================================================================
# General
# ==============================================================================

variable "project_id" {
  description = "GCP project ID where KMS resources are created"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "region" {
  description = "Region where the KMS keyring is created"
  type        = string
}

# ==============================================================================
# Keyring
# ==============================================================================

variable "keyring_name" {
  description = "Name of the KMS keyring. Defaults to '<project_name>-<environment>-keyring'"
  type        = string
  default     = null
}

# ==============================================================================
# Keys
# ==============================================================================

variable "keys" {
  description = <<EOT
Map of CryptoKey names to their configuration. Each key is created in the keyring.
Example:
keys = {
  "cloud-sql" = {
    rotation_period    = "7776000s"   # 90 days
    protection_level   = "SOFTWARE"
    iam_bindings       = [
      {
        role   = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
        member = "serviceAccount:service-12345@gcp-sa-cloud-sql.iam.gserviceaccount.com"
      }
    ]
  }
  "gke" = {}
}
EOT
  type = map(object({
    rotation_period  = optional(string, "7776000s")
    protection_level = optional(string, "SOFTWARE")
    purpose          = optional(string, "ENCRYPT_DECRYPT")
    iam_bindings = optional(list(object({
      role   = string
      member = string
    })), [])
  }))
  default = {}
}

# ==============================================================================
# Labels
# ==============================================================================

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
