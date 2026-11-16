variable "compartment_id" {
  description = <<-EOT
    OCID of the compartment the policy is ATTACHED to. A policy governs only its
    own compartment and that compartment's descendants. It must sit at or above
    every resource its statements grant access to, and at or above the OKE
    cluster itself. For this first cut that is the flat "dev" compartment.

    `compartment_id` is NOT UPDATABLE on `oci_identity_policy`.
  EOT
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID (ocid1.compartment.* / ocid1.tenancy.*)."
  }
}

variable "policy_name" {
  description = <<-EOT
    Name of the single `oci_identity_policy` this module creates.

    Two hard OCI facts make this the most dangerous input in the module:
      1. `name` is UNIQUE ACROSS THE ENTIRE TENANCY.
      2. `name` is NOT UPDATABLE - a change is a destroy-and-recreate.

    Consequence: NO REGION COMPONENT and NO APP COMPONENT. One object per
    environment, e.g. `<project>-<env>-oke-cluster-iam`. The regex validation
    rejects an OCI region identifier appearing anywhere in the name.
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]{0,98}[a-z0-9]$", var.policy_name))
    error_message = "policy_name must be lowercase alphanumeric with . _ - separators, 2-100 chars."
  }

  validation {
    condition     = length(regexall("(af|ap|ca|eu|il|me|mx|sa|uk|us)-[a-z]+-[0-9]", var.policy_name)) == 0
    error_message = "policy_name must not contain an OCI region identifier. Identity objects are environment-scoped, never region-scoped."
  }
}

variable "policy_description" {
  description = "Human-readable description of the policy. Updatable, unlike name and compartment_id."
  type        = string
  default     = null
}

variable "statements" {
  description = <<-EOT
    Pre-composed OCI policy statement strings, all written against
    `request.principal.type = 'cluster'` (the OKE cluster service principal the
    Cloud Controller Manager runs as). Concatenated into this module's single
    policy object.

    Contributed statements are whitespace-normalised and validated at plan time
    (see main.tf preconditions). The guard REQUIRES every statement to name the
    cluster principal type in a `where` clause - a bare `any-user ... in
    compartment ...` with no `where request.principal.type='cluster'` grants
    every principal in the tenancy and is rejected.

    Example (the two canonical OKE CCM/LB grants):
      "allow any-user to manage network-security-groups in compartment id <compartment_ocid> where request.principal.type='cluster'"
      "allow any-user to manage vcns in compartment id <compartment_ocid> where request.principal.type='cluster'"

    Empty policy statements are not something the OCI API accepts, so the
    module emits a single inert bootstrap statement (see locals.tf) while this
    list is empty - purely to claim the tenancy-unique, non-updatable name.
  EOT
  type        = list(string)
  default     = []
}

variable "max_statements" {
  description = <<-EOT
    Plan-time cap on the number of statements in this one policy object.
    Defaults to 50, OCI's documented hard per-policy-object limit. Two further
    limits are NOT checkable from inside a module and are the caller's
    responsibility: 100 policy objects per tenancy, and 500 statements per
    compartment hierarchy ("a hard limit that cannot be increased").
  EOT
  type        = number
  default     = 50

  validation {
    condition     = var.max_statements > 0 && var.max_statements <= 50
    error_message = "max_statements must be between 1 and 50."
  }
}

variable "version_date" {
  description = "Optional policy version date (YYYY-MM-DD). Null means always-current behaviour."
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Free-form tags applied to the policy."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to the policy, keyed \"namespace.key\"."
  type        = map(string)
  default     = {}
}