# oke-workload-identity - the OCI port of AWS `eks-iam` (IRSA). On OCI the grant
# IS the identity: a single policy statement names the (cluster, namespace,
# service_account) tuple in its `where all {}` clause. No role, no ARN, no
# annotation. THIS MODULE OWNS EXACTLY ONE POLICY OBJECT PER ENVIRONMENT.

variable "compartment_id" {
  description = <<-EOT
    OCID of the compartment the policy is ATTACHED to. This is not cosmetic: a
    policy governs only its own compartment and that compartment's descendants
    ("Policies in any of the sibling compartments cannot refer to the
    compartment of interest"). It must therefore sit at or above every resource
    any of its statements grants access to, and at or above the OKE cluster
    itself - otherwise an `oci_containerengine_cluster_workload_mapping` is
    additionally required per namespace.

    For this first cut that is the flat "dev" compartment, which holds both the
    cluster and everything its pods touch. Do NOT default this to the tenancy
    root: root would work, but it widens every statement's reachable location
    set to the whole tenancy for no benefit.

    `compartment_id` is NOT UPDATABLE on `oci_identity_policy` - changing it
    forces a destroy/create of every identity in this policy.
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

    Two hard OCI facts make this the most dangerous input in the whole port:

      1. `name` is UNIQUE ACROSS THE ENTIRE TENANCY.
      2. `name` is NOT UPDATABLE - a change is a destroy-and-recreate, i.e. a
         window in which every pod covered by this policy loses access.

    Consequences, both structural, both enforced below:

      * NO REGION COMPONENT. Compartments are tenancy-wide across regions, so a
        region-scoped identity object is incoherent as well as expensive: one
        object per app per region root at the current AWS footprint is
        12 x 11 = 132 objects against a hard 100-per-tenancy limit -
        unbuildable. The regex validation rejects an OCI region identifier
        appearing anywhere in the name.
      * NO APP COMPONENT. This module deliberately has no `app_name` input.
        The intended shape is `<project>-<env>-workload-identity`, ONE object
        per environment, into which every app module contributes statements
        (see `statements` / `workload_grants`). Creating one policy object per
        app is how the 100-object tenancy limit gets consumed.
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]{0,98}[a-z0-9]$", var.policy_name))
    error_message = "policy_name must be lowercase alphanumeric with . _ - separators, 2-100 chars. Lowercase because the OCI API normalises policy text and mixed case is a perpetual-diff source."
  }

  validation {
    condition     = length(regexall("(af|ap|ca|eu|il|me|mx|sa|uk|us)-[a-z]+-[0-9]", var.policy_name)) == 0
    error_message = "policy_name must not contain an OCI region identifier. Policy names are tenancy-unique and NOT updatable, and compartments are global across regions: identity objects are environment-scoped, never region-scoped. Fixing a regionalised name later destroys and recreates every identity in it."
  }
}

variable "policy_description" {
  description = "Human-readable description of the policy. Updatable, unlike name and compartment_id."
  type        = string
  default     = null
}

variable "cluster_ids" {
  description = <<-EOT
    OCIDs of EVERY OKE cluster in this environment whose workloads this policy
    authorises. A LIST FROM DAY ONE even though the dev cut has exactly one
    cluster - this is not speculative generality.

    `request.principal.cluster_id` is one of the four conditions that make up
    the entire security boundary; N clusters means N statements, not N policy
    objects. If this were `string`, adding a second cluster or a second region
    to an environment would force either a second policy object (100-object
    tenancy limit) or a renamed one (destroy/recreate of every identity).
    Widening it later is exactly the migration this list avoids.

    Also used to validate caller-contributed `statements`: any statement
    pinning a `request.principal.cluster_id` not in this list is rejected at
    plan time.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.cluster_ids) > 0
    error_message = "cluster_ids must contain at least one OKE cluster OCID. An empty list would render statements with no cluster condition, which grants every cluster in the tenancy."
  }

  validation {
    condition     = alltrue([for c in var.cluster_ids : can(regex("^ocid1\\.cluster\\.", c))])
    error_message = "every entry in cluster_ids must be an OKE cluster OCID (ocid1.cluster.*)."
  }
}

variable "workload_grants" {
  description = <<-EOT
    Structured grants, rendered by this module into statements. THE PREFERRED
    CONTRIBUTION CHANNEL - prefer it over `statements` wherever the grant fits
    this shape, because the renderer cannot forget a `where` condition.

    Why that matters: on AWS a malformed trust policy fails CLOSED (the
    AssumeRole call is rejected). On OCI a statement missing
    `request.principal.cluster_id` grants every cluster in the tenancy, and one
    missing `request.principal.service_account` grants every pod in the
    namespace - silently, with no error. The statement text is the security
    boundary, so it is rendered in exactly one place.

    Each grant is expanded across `cluster_ids`, so one entry with two clusters
    yields two statements.

      verb           - inspect | read | use | manage (cumulative lattice)
      resource_type  - e.g. secret-bundles, objects, metrics, log-content, repos
      compartment_id - location; defaults to this policy's own compartment.
                       Must be at or below `var.compartment_id` or the grant is
                       unreachable from where the policy is attached.
      condition      - extra `where all {}` term, e.g.
                       "target.bucket.name='hyps-dev-loki'". Rendered verbatim
                       after the four principal conditions; write it
                       pre-normalised (no spaces around `=`).
  EOT
  type = list(object({
    namespace       = string
    service_account = string
    verb            = string
    resource_type   = string
    compartment_id  = optional(string)
    condition       = optional(string)
  }))
  default = []

  validation {
    condition     = alltrue([for g in var.workload_grants : contains(["inspect", "read", "use", "manage"], lower(g.verb))])
    error_message = "workload_grants[*].verb must be one of inspect, read, use, manage."
  }

  validation {
    condition     = alltrue([for g in var.workload_grants : length(trimspace(g.namespace)) > 0 && length(trimspace(g.service_account)) > 0])
    error_message = "workload_grants[*].namespace and .service_account must be non-empty. A blank value renders a condition that matches nothing, or worse, is dropped."
  }

  validation {
    condition     = alltrue([for g in var.workload_grants : length(trimspace(g.resource_type)) > 0])
    error_message = "workload_grants[*].resource_type must be non-empty (e.g. secret-bundles, objects, metrics)."
  }
}

variable "statements" {
  description = <<-EOT
    Pre-composed policy statement strings contributed by callers, concatenated
    into this module's single policy object.

    This is the escape hatch that makes "one shared policy, many contributors"
    work: an app module that needs a grant this module's `workload_grants`
    shape cannot express (cross-tenancy Endorse/Admit, tag-based access
    control, a non-workload principal) contributes the STATEMENT, never its own
    `oci_identity_policy`. Adding policy objects per app is what consumes the
    100-object tenancy limit; adding statements consumes the far more
    generous - but still finite - statement budget.

    Contributed statements are whitespace-normalised and validated at plan time
    (see main.tf preconditions): every statement carrying
    `request.principal.type='workload'` must also carry all three of
    `.namespace`, `.service_account` and `.cluster_id`, and any cluster it
    pins must be in `var.cluster_ids`.

    Empty by default. Wave 1 has no ported app modules, so the policy object is
    created with a single inert bootstrap statement (see locals.tf) purely to
    claim the tenancy-unique name; it disappears the moment a real grant lands.
  EOT
  type        = list(string)
  default     = []
}

variable "max_statements" {
  description = <<-EOT
    Plan-time cap on the number of statements in this one policy object.

    Defaults to 50, which is OCI's documented hard per-policy-object limit.
    Two further limits are NOT checkable from inside a module and are the
    caller's responsibility:
      * 100 policy objects per tenancy;
      * 500 statements per compartment hierarchy - "a hard limit that cannot be
        increased" - which is a budget shared by every policy in the subtree.
    Lower this below 50 if you want an early warning against the 500 ceiling.
  EOT
  type        = number
  default     = 50

  validation {
    condition     = var.max_statements > 0 && var.max_statements <= 50
    error_message = "max_statements must be between 1 and 50. 50 is OCI's per-policy-object statement limit; a higher value would only defer an apply-time API rejection."
  }
}

variable "version_date" {
  description = "Optional policy version date (YYYY-MM-DD). Pins statement evaluation to OCI policy-language behaviour as of that date. Null means always-current behaviour."
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
