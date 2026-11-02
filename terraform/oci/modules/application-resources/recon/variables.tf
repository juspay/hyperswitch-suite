# recon - its own KMS key, object storage bucket, Vault read grants and policy
# statements, plus an optional dedicated database. With create_database=true it
# instantiates composition/database inline. THIS MODULE CREATES NO
# `oci_identity_policy` - see locals.tf.

# -----------------------------------------------------------------------------
# Identity and placement
# -----------------------------------------------------------------------------

variable "compartment_id" {
  description = <<-EOT
    OCID of the compartment this module's resources live in, and the default
    location term of every statement it renders. Must be the same compartment
    the shared `oke-workload-identity` policy is attached to, or a descendant:
    a policy governs only its own compartment and that compartment's
    descendants.
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
  description = "OCIDs of every OKE cluster whose workloads these grants authorise. A list from day one - N clusters means N statements, not N policy objects. Replaces the AWS module's `oidc_provider_arn` / `oidc_provider_id`."
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
  description = "The (namespace, name) pairs these grants authorise. Replaces the AWS `system:serviceaccount:<namespace>:<name>` list. The recon chart names its service account `hyperswitch-recon-role`."
  type = list(object({
    namespace = string
    name      = string
  }))
  default = [{ namespace = "recon-sandbox", name = "hyperswitch-recon-role" }]

  validation {
    condition     = length(var.service_accounts) > 0
    error_message = "service_accounts must contain at least one (namespace, name) pair."
  }

  validation {
    condition     = alltrue([for s in var.service_accounts : length(trimspace(s.namespace)) > 0 && length(trimspace(s.name)) > 0])
    error_message = "service_accounts[*].namespace and .name must be non-empty. A blank value renders a condition that matches nothing, or is dropped entirely - which widens the grant."
  }
}

# -----------------------------------------------------------------------------
# Permissions
# -----------------------------------------------------------------------------

variable "kms" {
  description = <<-EOT
    Recon's own customer-managed key, used by the service's `oci_kms` secrets
    manager (`vault_crypto_endpoint` + `key_id`). AWS: `module.kms` +
    `aws_iam_policy.recon_kms`. Same shape as the hyperswitch module's `kms`.

    `use_virtual_private_vault` has no AWS counterpart: OCI's
    `oci_kms_vault_replication` only supports a virtual private vault, and
    `vault_type` is NOT updatable in place, so the DR posture is chosen before
    the first apply.

    Deliberately absent: `aliases`, `key_administrators`, `key_users` and every
    other key-policy field. OCI key access is entirely policy-STATEMENT driven.

    Set `existing_key_id` to consume a key owned elsewhere instead of creating
    one; `create` and `existing_key_id` are mutually exclusive.
  EOT
  type = object({
    create                    = optional(bool, true)
    existing_key_id           = optional(string)
    vault_display_name        = optional(string)
    key_display_name          = optional(string)
    use_virtual_private_vault = optional(bool, false)
    key_algorithm             = optional(string, "AES")
    key_length                = optional(number, 32)
    protection_mode           = optional(string, "HSM")
    enable_key_rotation       = optional(bool, true)
    rotation_interval_in_days = optional(number, 365)
    create_replica            = optional(bool, false)
    replica_region            = optional(string)
  })
  default = {}

  validation {
    condition     = var.kms.rotation_interval_in_days >= 60 && var.kms.rotation_interval_in_days <= 365
    error_message = "kms.rotation_interval_in_days must be between 60 and 365 (OCI's documented range). AWS's default annual rotation maps to 365."
  }

  validation {
    condition     = contains(["HSM", "SOFTWARE"], var.kms.protection_mode)
    error_message = "kms.protection_mode must be HSM or SOFTWARE."
  }
}

variable "recon_bucket" {
  description = <<-EOT
    Recon bucket. AWS: `module.recon_bucket` (`s3_bucket_name`,
    `enable_s3_versioning`).

    `force_destroy` is DROPPED, not renamed: `oci_objectstorage_bucket` has no
    such argument in provider 9.0.0, and a bucket containing objects cannot be
    deleted by the resource at all. Empty it out of band first.
  EOT
  type = object({
    create             = optional(bool, true)
    bucket_name        = optional(string)
    versioning_enabled = optional(bool, true)
    storage_tier       = optional(string, "Standard")
  })
  default = {}
}

variable "secrets" {
  description = <<-EOT
    Read app secrets from OCI Vault. AWS: `aws_iam_policy.recon_secrets_manager`
    (`secretsmanager:GetSecretValue` + `DescribeSecret` on
    `secrets_manager_arns`).

    Two OCI grants, not one: GetSecretValue -> `read secret-bundles` (the
    VALUE), DescribeSecret -> `read secrets` (the METADATA).

    `secret_ids` empty renders both grants compartment-scoped - the breadth of
    the AWS unit's `*/hyperswitch-recon/secrets-*` wildcard, expressed as a
    compartment. Supplying OCIDs narrows to `target.secret.id='<ocid>'` per
    secret, at 2 statements PER SECRET PER SERVICE ACCOUNT PER CLUSTER against
    the 50-statement per-policy-object budget.
  EOT
  type = object({
    enabled    = optional(bool, true)
    secret_ids = optional(list(string), [])
  })
  default = {}
}

variable "extra_statements" {
  description = <<-EOT
    Raw policy statement strings appended to `policy_statements`. Replaces
    `additional_assume_role_statements`: OCI has no role and no assume
    operation. Write them pre-normalised and use `in compartment id <ocid>`.
  EOT
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Dedicated database
# -----------------------------------------------------------------------------

variable "create_database" {
  description = <<-EOT
    Provision a dedicated OCI Database with PostgreSQL system for recon, nested
    inside this module - the same shape the AWS module uses
    (`create_recon_database` -> `module.database` = `composition/database`).

    TLS is mandatory on OCI Database with PostgreSQL and cannot be turned off,
    and only the default `postgres` database exists: `hyperswitch_recon` and
    recon's migrations (which do not run at boot) are an out-of-band step.
  EOT
  type        = bool
  default     = false
}

variable "database_config" {
  description = <<-EOT
    Passed straight through to the nested `composition/database` module.

    `subnet_id` is required when `create_database` is true; everything else
    falls back to OCI-appropriate defaults (2 nodes across fault domains, DAILY
    backups with 7-day retention AND a separate 7-day PITR policy, reader
    endpoint on, warm standby off).

    Deliberately absent: every `global_cluster` field. Cross-region DR is
    `enable_warm_standby` + `primary_db_system_id`.
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
    admin_username              = optional(string, "hs_recon_app")
    vault_secret = optional(object({
      create         = optional(bool, false)
      vault_id       = optional(string)
      key_id         = optional(string)
      secret_id      = optional(string)
      secret_version = optional(number, 1)
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
  description = "Defined tags, keyed \"namespace.key\". Passed through untouched; this module owns no tag namespace."
  type        = map(string)
  default     = {}
}
