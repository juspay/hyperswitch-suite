# General configuration
variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string

  validation {
    condition     = contains(["dev", "integ", "prod", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, integ, prod, sandbox"
  }
}

variable "project_name" {
  description = "Project name used for naming and tagging"
  type        = string
  default     = "hyperswitch"
}

# OCI's unit of access control - but NOT the pull-URL scope: the compartment
# governs who may act on a repository; the tenancy NAMESPACE governs what the
# pull URL looks like and what names are taken. AWS collapses both into one.
variable "compartment_id" {
  description = "OCID of the compartment repositories are created in (IAM/organisational scope only - it does NOT appear in the pull URL)"
  type        = string

  validation {
    condition     = startswith(var.compartment_id, "ocid1.compartment.") || startswith(var.compartment_id, "ocid1.tenancy.")
    error_message = "compartment_id must be a compartment or tenancy OCID (ocid1.compartment... or ocid1.tenancy...)."
  }
}

# Carried through rather than read back: an OCIR repository exposes no region
# attribute (the region is a property of the provider connection), but the pull
# URL needs it.
variable "region" {
  description = "OCI region identifier the registry is addressed in (e.g. ap-mumbai-1). Used only to build pull URLs."
  type        = string
}

# The tenancy Object Storage namespace, which is also the OCIR namespace - the
# `<tenancy-namespace>` segment of `<region>.ocir.io/<tenancy-namespace>/<repo>`.
# null makes this module look it up itself with a read-only data source; supply
# it from the catalog root to save the API call and keep the plan independent of
# credentials being present.
variable "namespace" {
  description = "Object Storage / OCIR tenancy namespace (null looks it up via data.oci_objectstorage_namespace)"
  type        = string
  default     = null
}

# The pull endpoint host
# Oracle's OKE docs write this as `<region-key>.ocir.io` (e.g. `bom` for
# ap-mumbai-1); the full region-identifier form is also in current material. This
# module does NOT ship a region-key lookup table (a hard-coded key table silently
# rots); the default is built from the region identifier, and the override exists
# for anyone who has confirmed the key form is required in their region.
variable "ocir_endpoint" {
  description = "OCIR registry host (null defaults to \"<region>.ocir.io\"; set explicitly to the region-key form, e.g. \"bom.ocir.io\", if required)"
  type        = string
  default     = null
}

# Repositories

# NAME COLLISION WARNING - a real divergence, not a style preference. An ECR
# repository name is scoped to the AWS ACCOUNT; an OCIR repository name is unique
# across the entire TENANCY NAMESPACE regardless of compartment. If dev, integ
# and sandbox share one non-prod tenancy, two environments CANNOT both own a
# repository called `hyperswitch-router`. Hence this prefix: set it to "<env>/"
# (OCIR names may contain forward slashes, rendered as nesting in the console) so
# each environment gets its own namespace-unique path. Defaulting to "" would be
# the mechanical port and would fail on the second environment's apply.
variable "repository_name_prefix" {
  description = "Prefix prepended to every repository key to form its OCIR display name (e.g. \"dev/\"). Repository names are unique per TENANCY NAMESPACE, not per compartment - see the comment above this variable."
  type        = string
  default     = ""
}

variable "repositories" {
  description = <<-EOT
    Map of repository key to configuration. One `oci_artifacts_container_repository`
    per entry, mirroring the AWS module's `for_each = var.repositories` shape.

    The key becomes the repository name (with var.repository_name_prefix applied)
    unless display_name is set explicitly.

    Deliberately ABSENT compared with the AWS module's per-repository surface,
    each one a recorded gap rather than an omission:
      - lifecycle_policy   feature 7, NONE. No retention mechanism exists
                           anywhere in the oracle/oci provider. See main.tf.
      - repository_policy  feature 6, SUBSTITUTE. Moves to the compartment-level
                           IAM policy this module can optionally create; see
                           push_subjects / pull_subjects below.
      - scan_on_push       feature 4, NONE on this resource.
      - encryption_type /
        kms_key            feature 5, PARTIAL. No CMEK argument exists here.
      - force_delete       feature 8, PARTIAL. Empty the repository out of band
                           before `terraform destroy`.
  EOT

  type = map(object({
    display_name = optional(string)

    # Per-repository compartment override - AWS has nothing equivalent.
    compartment_id = optional(string)

    # Replaces AWS's image_tag_mutability; all-or-nothing per repository (no
    # exclusion-filter counterpart). null falls back to var.default_is_immutable.
    is_immutable = optional(bool)

    is_public = optional(bool, false)

    # New, OCI-only, cosmetic.
    readme = optional(object({
      content = string
      format  = string # "text/plain" or "text/markdown"
    }))

    freeform_tags = optional(map(string), {})
    defined_tags  = optional(map(string), {})
  }))

  default = {}

  validation {
    condition = alltrue([
      for k, v in var.repositories :
      v.readme == null || contains(["text/plain", "text/markdown"], try(v.readme.format, "text/plain"))
    ])
    error_message = "repository readme.format must be either \"text/plain\" or \"text/markdown\"."
  }
}

# Fleet-wide posture pinned as a module default rather than left to the provider
# (which is unset/false). Every AWS live repository reviewed is immutable; a
# repository that silently defaulted to mutable would be a security regression.
variable "default_is_immutable" {
  description = "Default is_immutable for repositories that do not set it. Defaults true, matching every AWS live repository reviewed."
  type        = bool
  default     = true
}

# Access control - the substitute for aws_ecr_repository_policy.
# OCI has no resource-attached policy. The AWS grant (a cross-account CI role
# with push/pull on each repository) becomes ONE compartment-scoped IAM policy
# naming a group or dynamic group. Both lists default empty, so the common case
# creates no policy at all - correct while the CI identity does not exist yet.
# NOT YET ORACLE-GATED - the mechanism is here, off by default; the decision to
# adopt it is still open.
variable "push_subjects" {
  description = "OCI IAM subjects granted push+pull on repositories in this compartment (e.g. [\"group CI-Pipeline\", \"dynamic-group ci-runners\"]). Empty creates no policy. Cross-TENANCY CI needs a formal Define/Endorse/Admit relationship instead - see check sheet feature 6."
  type        = list(string)
  default     = []
}

variable "pull_subjects" {
  description = "OCI IAM subjects granted read-only pull. Note that OKE node/pod image pulls do NOT go through IAM at all - see the auth-token comment in main.tf."
  type        = list(string)
  default     = []
}

# Tagging
variable "freeform_tags" {
  description = "Freeform tags merged onto every repository (the AWS `tags` / GCP `labels` analogue)"
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags (namespace.key = value). Requires the tag namespace to already exist in the tenancy."
  type        = map(string)
  default     = {}
}
