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
  description = "Project name used for naming and tagging"
  type        = string
  default     = "hyperswitch"
}

# OCI's unit of access control. Replaces AWS's implicit "whichever account this
# provider points at" - but NOT the pull-URL scope. See feature 2 of the check
# sheet and the repository_name_prefix variable below: the compartment governs
# who may act on the repository; the tenancy NAMESPACE governs what the pull URL
# looks like and what names are already taken. They are two different scopes and
# AWS collapses them into one.
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
# URL needs it. Same treatment as object-storage-backend's `region`.
variable "region" {
  description = "OCI region identifier the registry is addressed in (e.g. ap-mumbai-1). Used only to build pull URLs."
  type        = string
}

# The tenancy Object Storage namespace, which is also the OCIR namespace - the
# `<tenancy-namespace>` segment of `<region>.ocir.io/<tenancy-namespace>/<repo>`.
# Confirmed in the check sheet (section 5) to be the same value for both
# services. null makes this module look it up itself with a read-only data
# source, which is cheap; supply it from root.hcl's `namespace` local to save
# the API call and to keep the plan independent of credentials being present.
variable "namespace" {
  description = "Object Storage / OCIR tenancy namespace (null looks it up via data.oci_objectstorage_namespace)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# The pull endpoint host
# -----------------------------------------------------------------------------
# Oracle's OKE pull documentation writes this as `<region-key>.ocir.io` (the
# three-letter key, e.g. `bom` for ap-mumbai-1). The full region identifier form
# (`ap-mumbai-1.ocir.io`) is also in current Oracle material. This module does
# NOT ship a region-key lookup table, because a hard-coded key table is exactly
# the kind of thing that silently rots; the default is built from the region
# identifier and this override exists for anyone who has confirmed the key form
# is required in their region.
variable "ocir_endpoint" {
  description = "OCIR registry host (null defaults to \"<region>.ocir.io\"; set explicitly to the region-key form, e.g. \"bom.ocir.io\", if required)"
  type        = string
  default     = null
}

# =============================================================================
# Repositories
# =============================================================================

# -----------------------------------------------------------------------------
# NAME COLLISION WARNING - a real divergence from AWS, not a style preference.
#
# An ECR repository name is scoped to the AWS ACCOUNT. `hyperswitch-router` in
# the sandbox account and `hyperswitch-router` in a prod account are two
# unrelated repositories. An OCIR repository name is unique across the entire
# TENANCY NAMESPACE, regardless of compartment (check sheet feature 2). If dev,
# integ and sandbox share one non-prod tenancy - which is what
# docs/multi-cloud-parity/oci/identity-model.md section 4.1 recommends - then two
# environments CANNOT both own a repository called `hyperswitch-router`.
#
# Hence this prefix. Set it to "<env>/" (OCIR names may contain forward slashes,
# which render as nesting in the console) so each environment gets its own
# namespace-unique path. Defaulting it to "" would be the mechanical port and
# would fail on the second environment's apply.
# -----------------------------------------------------------------------------
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

    # Per-repository compartment override. AWS has nothing equivalent because a
    # repository has no placement at all beyond its account.
    compartment_id = optional(string)

    # Replaces AWS's image_tag_mutability. All-or-nothing per repository: there
    # is no `image_tag_mutability_exclusion_filter` counterpart (feature 3,
    # PARTIAL). null falls back to var.default_is_immutable.
    is_immutable = optional(bool)

    is_public = optional(bool, false)

    # New, OCI-only, cosmetic. The AWS module has no counterpart.
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

# The fleet-wide posture, pinned as a module default rather than left to the
# provider's (which is unset/false). Every ECR repository in every AWS live root
# reviewed is IMMUTABLE; a repository that silently defaulted to mutable would be
# a security regression introduced by the port.
variable "default_is_immutable" {
  description = "Default is_immutable for repositories that do not set it. Defaults true, matching every AWS live repository reviewed."
  type        = bool
  default     = true
}

# =============================================================================
# Access control - the SUBSTITUTE for aws_ecr_repository_policy (feature 6)
# =============================================================================
# OCI has no resource-attached policy document. The AWS grant (a cross-account
# Jenkins CI role given push/pull on each of ~130 repositories) becomes ONE
# compartment-scoped IAM policy naming a group or dynamic group. Both lists
# default empty, so the common case creates no policy at all - which is correct
# while the CI identity does not exist yet.
#
# NOT YET ORACLE-GATED. Check sheet section 8 item 2 requires the gate on this
# verdict, and it has not been convened. What is here is the mechanism, off by
# default; the decision to use it is still open.

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

# =============================================================================
# Tagging
# =============================================================================

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
