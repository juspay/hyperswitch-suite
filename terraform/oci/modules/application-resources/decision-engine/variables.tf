# decision-engine - OCI port of application-resources/decision-engine.
# A hybrid of `superposition`'s generic role-factory surface plus two of
# hyperswitch's hardcoded feature-flagged policies (its own bucket, and SES).
# It creates no `oci_identity_policy` - see locals.tf.

variable "compartment_id" {
  description = "OCID of the compartment this module's resources live in, and the default location term of every statement it renders. Must be in the same subtree as the shared `oke-workload-identity` policy AND as hyperswitch's KMS key (identity-model.md section 3.4)."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID."
  }
}

variable "environment" {
  description = "Short environment name (dev / integ / sandbox / prod)."
  type        = string
}

variable "project_name" {
  description = "Project name prefix used in resource naming."
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "OCI region identifier, e.g. ap-mumbai-1."
  type        = string
}

variable "cluster_ids" {
  description = "OCIDs of every OKE cluster whose workloads these grants authorise. A list from day one - N clusters means N statements, not N policy objects."
  type        = list(string)

  validation {
    condition     = length(var.cluster_ids) > 0
    error_message = "cluster_ids must contain at least one OKE cluster OCID."
  }

  validation {
    condition     = alltrue([for c in var.cluster_ids : can(regex("^ocid1\\.cluster\\.", c))])
    error_message = "every entry in cluster_ids must be an OKE cluster OCID (ocid1.cluster.*)."
  }
}

variable "service_accounts" {
  description = "The (namespace, name) pairs these grants authorise. Defaults to the one pair the real catalog unit manages: `decision-engine/decision-engine-sa`."
  type = list(object({
    namespace = string
    name      = string
  }))
  default = [{ namespace = "decision-engine", name = "decision-engine-sa" }]

  validation {
    condition     = length(var.service_accounts) > 0
    error_message = "service_accounts must contain at least one (namespace, name) pair."
  }
}

variable "kms_key_id" {
  description = <<-EOT
    OCID of hyperswitch's KMS key, read cross-module exactly as the AWS unit
    reads `dependency.hyperswitch.outputs.kms_key_arn`. One statement:
    `use keys` scoped `target.key.id`.

    Notable: the GCP catalog unit for this module has NO KMS input at all, even
    though the real AWS catalog unit grants one - a fork between what GCP's
    authors expected this module to need and what AWS actually grants. Carried
    to the gate (check sheet section 1) rather than silently resolved. Null here
    means the grant is not emitted.
  EOT
  type        = string
  default     = null
}

variable "extra_statements" {
  description = <<-EOT
    Raw policy statement strings appended to `policy_statements`. Replaces
    `aws_managed_policy_names` (feature 3, NONE - no canned-policy library),
    `customer_managed_policy_arns` (feature 4, SUBSTITUTE - `shared-policy`
    becomes a statement-text factory) and `inline_policies` at once.

    Write them pre-normalised and use `in compartment id <ocid>`.
  EOT
  type        = list(string)
  default     = []
}

variable "bucket" {
  description = <<-EOT
    This module's own dedicated bucket. AWS: `module.s3_bucket`
    (`terraform-aws-modules/s3-bucket/aws`) plus `aws_iam_policy.s3_policy`
    covering PutObject / GetObject / ListBucket / GetObjectVersion /
    DeleteObject / GetBucketLocation - SIX AWS actions that collapse into one
    OCI verb, `manage objects`.

    `cloudfront_distribution_arns` IS DROPPED, not renamed (feature 7, verdict
    NONE). OCI has no first-party CDN: the closest offering, "CDN Interconnect",
    is a third-party Cloudflare peering arrangement available only in North
    America with no `oci_*` resource behind it. There is therefore nothing for
    an Origin-Access-Control bucket policy to attach to. Unused on AWS today
    (`[]`), so the blast radius is zero - but if a CDN in front of this bucket
    is ever required it is a new architecture decision needing its own oracle
    gate pass, not a parameter on this module. Check sheet section 4.1.

    `force_destroy` is likewise absent: `oci_objectstorage_bucket` has no such
    argument and a non-empty bucket cannot be deleted by the resource.

    NAMING. The AWS module auto-generates `hyperswitch-decision-engine-<env>-
    <region>` specifically to dodge S3's global name collisions. OCI bucket
    names are unique only within the tenancy's Object Storage namespace, so the
    region suffix buys nothing - but that is a convention choice that should be
    made once for the whole OCI module set, not per module (check sheet section
    9 Q3). The default below drops the region suffix; override `bucket_name` to
    keep it.
  EOT
  type = object({
    create             = optional(bool, true)
    bucket_name        = optional(string)
    versioning_enabled = optional(bool, true)
    storage_tier       = optional(string, "Standard")
    lifecycle_rules = optional(list(object({
      name        = string
      action      = string
      time_amount = number
      time_unit   = optional(string, "DAYS")
      target      = optional(string)
      is_enabled  = optional(bool, true)
      object_name_filter = optional(object({
        inclusion_prefixes = optional(list(string))
        inclusion_patterns = optional(list(string))
        exclusion_patterns = optional(list(string))
      }))
    })), [])
  })
  default = {}
}

variable "bucket_noncurrent_version_expiry_days" {
  description = <<-EOT
    Convenience for the ONE lifecycle rule the real AWS catalog unit sets: a
    30-day noncurrent-version expiration. Rendered as an
    `oci_objectstorage_object_lifecycle_policy` rule with
    `target = "previous-object-versions"`.

    A separate resource on OCI rather than an inline `lifecycle_rule` block on
    the bucket - a structural difference, not a capability gap.

    Set to null to emit no rule and drive everything from `bucket.lifecycle_rules`
    instead. Whether 30 days is right on OCI's pricing tiers rather than AWS's
    is check sheet section 9 Q2, unanswered.
  EOT
  type        = number
  default     = 30
}

variable "email" {
  description = <<-EOT
    Transactional email. Replaces the AWS `ses` object entirely - no role to
    assume, a domain to verify (identical mechanics to hyperswitch.md section
    4.2, cited not re-derived).

    THE SHARING QUESTION, LEFT OPEN ON PURPOSE. This module and `hyperswitch`
    use the SAME cross-account SES role today, which means one logical sender.
    Check sheet section 4.2 recommends ONE shared `oci_email_email_domain` /
    `oci_email_sender` pair across both rather than two independent DNS
    verifications of the same domain - duplicated verification work and a second
    DNS-record burden for no isolation benefit. That is an oracle gate item
    (section 8 item 2) and is NOT YET CONSULTED, so both paths are buildable:

      * `use_existing_domain_id` / `use_existing_sender_id` set  -> share
        hyperswitch's, create nothing here. RECOMMENDED, pending the gate.
      * `create = true` with `domain_name` / `sender_address`    -> own a
        second, independent verified domain.

    The identity path is the same unresolved question hyperswitch carries: the
    workload-identity `use email-family` grant is primary and unconditional,
    and whether OCI Email Delivery's HTTPS `SubmitEmail` endpoint honours a
    workload principal is check sheet hyperswitch.md section 9 Q1.
  EOT
  type = object({
    enabled                = optional(bool, true)
    create                 = optional(bool, false)
    domain_name            = optional(string)
    sender_address         = optional(string)
    use_existing_domain_id = optional(string)
    use_existing_sender_id = optional(string)
  })
  default = {}

  validation {
    condition     = !try(var.email.create, false) || (try(var.email.domain_name, null) != null && try(var.email.sender_address, null) != null)
    error_message = "email.domain_name and email.sender_address are both required when email.create is true. Prefer use_existing_domain_id, pointed at hyperswitch's domain - the two modules send as the same logical sender today."
  }
}

variable "freeform_tags" {
  description = "Freeform tags merged onto every resource. The AWS `tags` analogue."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags, keyed \"namespace.key\". Passed through untouched."
  type        = map(string)
  default     = {}
}
