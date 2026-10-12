# superposition - a generic ROLE FACTORY whose three permission surfaces
# (managed / customer-managed / inline) collapse into `extra_statements` here,
# because OCI grants only via authored statements. With create_database=true it
# instantiates composition/database inline. THIS MODULE CREATES NO
# `oci_identity_policy` - see locals.tf.

# -----------------------------------------------------------------------------
# Identity and placement
# -----------------------------------------------------------------------------

variable "compartment_id" {
  description = <<-EOT
    OCID of the compartment this module's resources live in, and the default
    location term of every statement it renders. Must be the same compartment
    the shared `oke-workload-identity` policy is attached to, or a descendant.

    It must ALSO be in the same subtree as `hyperswitch`'s KMS key, since this
    module's only live grant reaches that key: a policy in a sibling
    compartment cannot refer to it, and a cross-subtree grant would need an
    `oci_containerengine_cluster_workload_mapping` - which is namespace-granular
    only and therefore strictly coarser than the service-account condition.
  EOT
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
  description = "The (namespace, name) pairs these grants authorise. Defaults to the one pair the real catalog unit manages: `superposition/superposition-role`."
  type = list(object({
    namespace = string
    name      = string
  }))
  default = [{ namespace = "superposition", name = "superposition-role" }]

  validation {
    condition     = length(var.service_accounts) > 0
    error_message = "service_accounts must contain at least one (namespace, name) pair."
  }
}

# -----------------------------------------------------------------------------
# Permissions
# -----------------------------------------------------------------------------

variable "kms_key_id" {
  description = <<-EOT
    OCID of the KMS key this workload may encrypt and decrypt with - in
    practice, `hyperswitch`'s key, read cross-module exactly as the AWS unit
    reads `dependency.hyperswitch.outputs.kms_key_arn` today. THIS MODULE DOES
    NOT OWN A KEY, and that asymmetry is real on AWS too.

    One statement: `use keys` scoped `target.key.id`. `use keys` = READ +
    KEY_ENCRYPT + KEY_DECRYPT + KEY_EXPORT + KEY_SIGN + KEY_VERIFY, which covers
    AWS's `kms:Decrypt` + `kms:Encrypt` in a single verb.

    UNRESOLVED FORK, worth knowing before you set this. The GCP precedent
    (`gcp/modules/application-resources/superposition`) grants NO app-level KMS
    permission at all: it routes encryption through the database layer's own
    CMEK and has no `google_kms_crypto_key_iam_member` anywhere. AWS keeps the
    app-level grant. Neither is obviously the target, and OCI Database with
    PostgreSQL has no CMEK support at all, which
    weakens the case for following GCP. Null here means the grant is not emitted.
  EOT
  type        = string
  default     = null
}

variable "extra_statements" {
  description = <<-EOT
    Raw policy statement strings appended to `policy_statements`.

    Replaces ALL THREE of the AWS module's permission surfaces at once:
      * `aws_managed_policy_names`      - feature 3, verdict NONE. OCI has no
        library of predefined, attachable-by-name policy objects. Oracle's
        `commonpolicies.htm` publishes suggested statement TEXT, which is
        something to copy, not an object to reference.
      * `customer_managed_policy_arns`  - feature 4, verdict SUBSTITUTE. This is
        the `shared-policy` consumer contract; on OCI `shared-policy` becomes a
        statement-text factory, so what flows in here is strings rather than
        ARNs.
      * `inline_policies`               - feature 5's generic half.

    Nothing is lost in capability; what is lost is attach-by-well-known-name.

    Write them pre-normalised and use `in compartment id <ocid>`, never
    `in compartment <name>` - the API lowercases compartment names in statement
    text and produces a perpetual diff.
  EOT
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Dedicated database
# -----------------------------------------------------------------------------

variable "create_database" {
  description = <<-EOT
    Provision a dedicated OCI Database with PostgreSQL system for this service,
    nested inside this module - the same shape the AWS module uses today
    (`module.database` = `composition/database`, `count = var.create_database`).

    Live AWS behaviour, carried across unchanged: true everywhere except
    `sandbox`, which points at a shared instance out of band.

    The database half is NOT re-derived here. Four things
    diverge from Aurora in ways the inputs do not show: TLS is mandatory,
    ap-mumbai-1 has one availability domain, cross-region DR has a 300 s RPO
    floor with manual failover, and restore is forfeited while that DR is on.
  EOT
  type        = bool
  default     = false
}

variable "database_config" {
  description = <<-EOT
    Passed straight through to the nested `composition/database` module. One
    object rather than ~47 flattened `database_*` variables - the same call the
    GCP precedent made, and the reason its own surface is readable.

    `subnet_id` is required when `create_database` is true; everything else
    falls back to the composition module's own defaults, which are already the
    OCI-appropriate ones (2 nodes across fault domains, DAILY backups with 7-day
    retention AND a separate 7-day PITR policy, reader endpoint on, warm standby
    off).

    Deliberately absent: every `global_cluster` field. There is no
    global-cluster object on OCI; cross-region DR is `enable_warm_standby` +
    `primary_db_system_id`, which are exposed here under their real names rather
    than under Aurora's.
  EOT
  type = object({
    subnet_id                   = optional(string)
    vcn_id                      = optional(string)
    create_nsg                  = optional(bool, true)
    nsg_ids                     = optional(list(string), [])
    display_name                = optional(string)
    db_version                  = optional(string, "17")
    config_overrides            = optional(map(string), {})
    shape                       = optional(string, "PostgreSQL.VM.Standard.E5.Flex")
    instance_ocpu_count         = optional(number, 2)
    instance_memory_size_in_gbs = optional(number, 32)
    instance_count              = optional(number, 2)
    storage_iops                = optional(number)
    is_regionally_durable       = optional(bool, true)
    availability_domain         = optional(string)
    is_reader_endpoint_enabled  = optional(bool, true)
    admin_username              = optional(string, "superposition")
    vault_secret = optional(object({
      create   = optional(bool, false)
      vault_id = optional(string)
      key_id   = optional(string)
    }))
    backup_kind            = optional(string, "DAILY")
    backup_start_hour      = optional(string, "00")
    backup_retention_days  = optional(number, 7)
    backup_copy_regions    = optional(list(string), [])
    pitr_restore_days      = optional(number, 7)
    enable_warm_standby    = optional(bool, false)
    primary_db_system_id   = optional(string)
    is_rpo_enforced        = optional(bool, true)
    rpo_in_seconds         = optional(number, 300)
    query_insights_enabled = optional(bool, true)
    enable_service_logs    = optional(bool, true)
    log_retention_duration = optional(number, 30)
  })
  default = {}
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

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
