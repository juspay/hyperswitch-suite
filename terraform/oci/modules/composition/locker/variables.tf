# =============================================================================
# composition/locker (OCI) - inputs
# =============================================================================
# The AWS module has 22 variables. This one has fewer, and the reductions are
# deliberate rather than incidental. Dropped with no counterpart, each traced
# to its check sheet entry:
#
#   ami_id, instance_type, instance_count, user_data, locker_subnet_ids,
#   alb_subnet_ids, alb_listeners, enable_alb_deletion_protection, locker_port
#       -> features 11/12/13 are N/A under this port's shape: the card vault
#          runs as an OKE workload, not a VM fleet behind an ALB. See the
#          header of database.tf. This is an open oracle-gate decision.
#   key_name, create_key_pair, public_key
#       -> feature 1's auto-generate branch is the state-exposure problem this
#          port exists to not reproduce, and with no VM there is nothing to
#          authenticate to. See versions.tf and secrets.tf.
#   additional_policy_arns
#       -> feature 10. There is no attachable policy object on OCI; the escape
#          hatch is contributing statements to the one shared policy, which the
#          catalog unit does directly. See identity.tf.
#
# Added with no AWS counterpart:
#   vcn_id, vault.*, k8s_namespace, k8s_service_account_name.

# -----------------------------------------------------------------------------
# Identity and naming
# -----------------------------------------------------------------------------

variable "compartment_id" {
  description = "OCID of the compartment every resource in this module is created in. Replaces the AWS module's implicit account scope. Note that a workload-identity grant can only reach the compartment the shared policy is attached to and its descendants, so this must sit at or below that attachment point."
  type        = string
}

variable "environment" {
  description = "Environment short name (dev, sandbox, prod). First component of every display name."
  type        = string
}

variable "project_name" {
  description = "Project short name (e.g. hyps). Second component of every display name."
  type        = string
}

variable "region" {
  description = "OCI region identifier (e.g. ap-mumbai-1). Not consumed by any resource here - the provider carries the region - but kept so every OCI composition unit passes the same four identity inputs and so cross-region DR values have somewhere to be validated against later."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional freeform tags, merged over this module's own. The AWS module's `tags`; OCI's freeform_tags is the tags_all analogue."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "OCI defined tags, passed through untouched. No AWS counterpart - defined tags need a tag namespace this module does not own."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Network placement
# -----------------------------------------------------------------------------

variable "vcn_id" {
  description = "OCID of the VCN, from composition/vpc-network's `vcn_id` output. Needed only to create this module's NSG - an NSG is a VCN-scoped object. Replaces the AWS module's vpc_id."
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet the card vault's database is placed in - vpc-network's `locker-database` tier, whose route table carries NO gateway routes at all (not internet, not NAT, not the service gateway). Singular and FORCE-NEW: OCI has no db-subnet-group, so the AWS module's database_config.subnet_ids list and create_db_subnet_group have no counterpart."
  type        = string
  default     = null
}

variable "create_nsg" {
  description = "Create the module-owned, deliberately EMPTY network security group for the locker database and export its OCID. composition/security-rules - the last stack phase - writes the rules into it. Mirrors the AWS module's create_security_group; see network.tf for why the rules are not here."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Key custody - AWS's nested terraform-aws-modules/kms/aws
# -----------------------------------------------------------------------------

variable "vault" {
  description = <<-EOT
    The OCI Vault holding this module's key and secrets.

    No AWS counterpart: an OCI key lives inside a vault, and crypto calls go to
    that vault's endpoint, so "create a KMS key" is a two-object operation.
    This module creates its OWN vault by default rather than using the
    environment's shared one, for the same reason the AWS module creates its
    own KMS key - the card vault's key custody boundary is its PCI-DSS scope
    boundary.

      create              - build a dedicated vault (default) or use an
                            existing one.
      vault_id            - required when create = false.
      management_endpoint - required when create = false; oci_kms_key takes the
                            endpoint, not a vault id.
      vault_type          - DEFAULT is the multi-tenant HSM partition and the
                            AWS KMS equivalent. VIRTUAL_PRIVATE is a dedicated
                            single-tenant HSM partition - stronger than plain
                            AWS KMS, which needs a CloudHSM custom key store to
                            match it - and materially more expensive. Parity,
                            not improvement, is the default.
      replica_region      - cross-region vault replication, the analogue of the
                            AWS module's kms.multi_region + create_replica used
                            by the passive stack. Vault-granular, not
                            key-granular. See kms.tf.
  EOT
  type = object({
    create              = optional(bool, true)
    vault_id            = optional(string)
    management_endpoint = optional(string)
    display_name        = optional(string)
    vault_type          = optional(string, "DEFAULT")
    replica_region      = optional(string)
  })
  default = {}

  validation {
    condition     = contains(["DEFAULT", "VIRTUAL_PRIVATE"], var.vault.vault_type)
    error_message = "vault.vault_type must be DEFAULT or VIRTUAL_PRIVATE."
  }

  validation {
    condition     = var.vault.create || (var.vault.vault_id != null && var.vault.management_endpoint != null)
    error_message = "vault.create = false requires both vault.vault_id and vault.management_endpoint - oci_kms_key is bound to a vault by its management endpoint, not by a vault id."
  }
}

variable "kms_key" {
  description = <<-EOT
    The card vault's dedicated encryption key (check sheet feature 14, FULL).

      algorithm / length  - AES with length in BYTES, not bits. 32 = AES-256,
                            the AWS SYMMETRIC_DEFAULT equivalent.
      protection_mode     - HSM (default, matching AWS KMS's default posture)
                            or SOFTWARE.
      auto_rotation_interval_in_days
                          - AWS's enable_key_rotation + rotation_period_in_days
                            in one field. OCI's window is 60-365 days, narrower
                            than AWS's. null disables rotation, which this
                            module does not do by default and neither does AWS.
      additional_key_ids  - AWS's kms.key_arns passthrough, concatenated into
                            the key_ids output.

    NOTE, and it is the important one: this key does NOT encrypt the database.
    oci_psql_db_system has no customer-managed-key argument at all in provider
    9.0.0. This key protects Vault secrets. See database.tf's storage note.
  EOT
  type = object({
    create                         = optional(bool, true)
    key_id                         = optional(string)
    display_name                   = optional(string)
    algorithm                      = optional(string, "AES")
    length                         = optional(number, 32)
    protection_mode                = optional(string, "HSM")
    auto_rotation_interval_in_days = optional(number, 90)
    additional_key_ids             = optional(list(string), [])
  })
  default = {}

  validation {
    condition     = contains(["HSM", "SOFTWARE"], var.kms_key.protection_mode)
    error_message = "kms_key.protection_mode must be HSM or SOFTWARE. HSM is the default and the AWS-parity choice; do not lower it for the card vault."
  }

  validation {
    condition = (
      var.kms_key.auto_rotation_interval_in_days == null ||
      (var.kms_key.auto_rotation_interval_in_days >= 60 && var.kms_key.auto_rotation_interval_in_days <= 365)
    )
    error_message = "kms_key.auto_rotation_interval_in_days must be between 60 and 365 (OCI's supported window), or null to disable rotation."
  }

  validation {
    condition     = var.kms_key.create || var.kms_key.key_id != null
    error_message = "kms_key.create = false requires kms_key.key_id."
  }
}

# -----------------------------------------------------------------------------
# The database credential
# -----------------------------------------------------------------------------

variable "db_admin_secret" {
  description = <<-EOT
    Where the card vault database's admin password comes from.

    THERE IS NO PLAINTEXT-PASSWORD OPTION HERE, BY DESIGN. The AWS module's
    tls_private_key/SSM pattern and the sibling composition/database module's
    random_password both put a credential into Terraform state; for the card
    vault that is the specific thing this port set out not to reproduce
    (check sheet section 4.2, master-checksheet.md finding A1). Two paths only:

      create = true (default) - OCI Vault GENERATES the value server-side
          (`enable_auto_generation` + `secret_generation_context`). Terraform
          sends a shape and receives an OCID and a version number; the
          plaintext is never a Terraform value, so it cannot reach state, a
          plan file, or a CI log.
      create = false          - point at a secret you already own via
          secret_id + secret_version.

      generation_type     - PASSPHRASE | SSH_KEY | BYTES.
      generation_template - PASSPHRASE: SECRETS_DEFAULT_PASSWORD |
                            DBAAS_DEFAULT_PASSWORD.
                            SSH_KEY: RSA_2048 | RSA_3072 | RSA_4096.
      passphrase_length   - max 32 (30 for the DBAAS template).
      secret_template     - forces the stored content to be the bare value
                            rather than the template default's JSON envelope.
                            oci_psql_db_system reads the bundle verbatim as the
                            password, so an envelope would set a password
                            nobody can reproduce.
  EOT
  type = object({
    create              = optional(bool, true)
    secret_id           = optional(string)
    secret_version      = optional(string)
    secret_name         = optional(string)
    generation_type     = optional(string, "PASSPHRASE")
    generation_template = optional(string, "SECRETS_DEFAULT_PASSWORD")
    passphrase_length   = optional(number, 30)
    secret_template     = optional(string, "%GENERATED_PASSPHRASE%")
  })
  default = {}

  validation {
    condition     = contains(["PASSPHRASE", "SSH_KEY", "BYTES"], var.db_admin_secret.generation_type)
    error_message = "db_admin_secret.generation_type must be PASSPHRASE, SSH_KEY or BYTES."
  }

  validation {
    condition = contains(
      ["SECRETS_DEFAULT_PASSWORD", "DBAAS_DEFAULT_PASSWORD", "RSA_2048", "RSA_3072", "RSA_4096", "BYTES_512", "BYTES_1024"],
      var.db_admin_secret.generation_template
    )
    error_message = "db_admin_secret.generation_template must be one of SECRETS_DEFAULT_PASSWORD, DBAAS_DEFAULT_PASSWORD (PASSPHRASE), RSA_2048/RSA_3072/RSA_4096 (SSH_KEY) or BYTES_512/BYTES_1024 (BYTES)."
  }

  validation {
    condition     = var.db_admin_secret.passphrase_length == null || (var.db_admin_secret.passphrase_length >= 16 && var.db_admin_secret.passphrase_length <= 30)
    error_message = "db_admin_secret.passphrase_length must be 16-30. OCI's ceiling is 32 for SECRETS_DEFAULT_PASSWORD and 30 for DBAAS_DEFAULT_PASSWORD; 30 is used as the common cap so the template can be switched without a length change."
  }

  validation {
    condition     = var.db_admin_secret.create || var.db_admin_secret.secret_id != null
    error_message = "db_admin_secret.create = false requires db_admin_secret.secret_id (and normally .secret_version). This module has no plaintext-password input."
  }
}

# -----------------------------------------------------------------------------
# The dedicated database
# -----------------------------------------------------------------------------

variable "create_database" {
  description = "Provision the card vault's OWN dedicated database. The AWS module's create_locker_database, which is true in every real instantiation seen. false leaves this module owning only the vault, key and identity contributions, for a caller pointing the vault at a database managed elsewhere - the same escape hatch GCP's create_database provides."
  type        = bool
  default     = true
}

variable "database_config" {
  description = <<-EOT
    The dedicated database's configuration. AWS's database_config passes ~70
    fields into a nested composition/database; this is the subset that exists
    on OCI, with the AWS names kept wherever the semantics survived.

    Notable non-arrivals, all documented at their point of divergence in
    database.tf / configuration.tf:
      storage_encrypted + kms  -> no CMEK argument exists (feature 17, PARTIAL)
      deletion_protection      -> no such field (feature 19, NONE); the module
                                  hardcodes lifecycle.prevent_destroy instead
      create_custom_parameter_group with rds.force_ssl = "0"
                               -> TLS cannot be disabled (feature 18, NONE -
                                  and the port is STRONGER for it)
      create_global_cluster / global_cluster_identifier /
      replication_source_identifier / source_region
                               -> collapse into primary_db_system_id; warm
                                  standby is a different architecture, not a
                                  renamed Aurora Global Database (feature 16,
                                  SUBSTITUTE)
      cluster_instances        -> sizing is db-system-level; every node is
                                  identical and there is no promotion_tier
      database_name            -> provider 9.0.0 has no oci_psql_database
                                  resource. Only the default `postgres`
                                  database is created; the card vault's own
                                  database is a manual `CREATE DATABASE` step,
                                  exactly as GCP hit on AlloyDB.
  EOT
  type = object({
    display_name = optional(string)
    db_version   = optional(string, "17")

    shape                       = optional(string, "PostgreSQL.VM.Standard.E5.Flex")
    instance_count              = optional(number, 2)
    instance_ocpu_count         = optional(number, 2)
    instance_memory_size_in_gbs = optional(number, 32)

    storage_system_type   = optional(string, "OCI_OPTIMIZED_STORAGE")
    storage_iops          = optional(number)
    is_regionally_durable = optional(bool, true)
    availability_domain   = optional(string)

    additional_nsg_ids             = optional(list(string), [])
    is_reader_endpoint_enabled     = optional(bool, true)
    primary_db_endpoint_private_ip = optional(string)

    admin_username = optional(string, "locker_admin")

    config_overrides = optional(map(string), {})
    config_id        = optional(string)
    apply_config     = optional(string, "RESTART")

    backup_kind              = optional(string, "DAILY")
    backup_start_hour        = optional(string, "00")
    backup_retention_days    = optional(number, 7)
    backup_days_of_the_week  = optional(list(string))
    backup_days_of_the_month = optional(list(number))
    backup_copy_regions      = optional(list(string), [])
    pitr_restore_days        = optional(number, 7)
    maintenance_window_start = optional(string)

    query_insights_enabled = optional(bool, true)

    enable_warm_standby              = optional(bool, false)
    primary_db_system_id             = optional(string)
    is_rpo_enforced                  = optional(bool, true)
    rpo_in_seconds                   = optional(number, 300)
    apply_change_mode_to_stand_alone = optional(bool)
  })
  default = {}

  validation {
    condition     = var.database_config.instance_count >= 1 && var.database_config.instance_count <= 8
    error_message = "database_config.instance_count must be 1-8 (one required primary plus up to seven read replicas)."
  }

  validation {
    condition     = var.database_config.rpo_in_seconds >= 300 && var.database_config.rpo_in_seconds <= 10800
    error_message = "database_config.rpo_in_seconds must be 300-10800. 300 s is OCI's FLOOR - there is no setting that reaches Aurora Global Database's sub-second observed lag, which is the substance of the feature 16 SUBSTITUTE verdict."
  }

  validation {
    condition     = contains(["DAILY", "WEEKLY", "MONTHLY"], var.database_config.backup_kind)
    error_message = "database_config.backup_kind must be DAILY, WEEKLY or MONTHLY."
  }

  validation {
    condition     = var.database_config.pitr_restore_days >= 1
    error_message = "database_config.pitr_restore_days must be at least 1. On AWS one number covered both backup retention and the PITR window; on OCI they are independent policies and omitting this ships the card vault's database with NO point-in-time recovery."
  }
}

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------

variable "enable_service_logs" {
  description = "Create the log group and ship the database's engine log to OCI Logging. The nested AWS database's enabled_cloudwatch_logs_exports = [\"postgresql\"] equivalent."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention in days. The AWS module's log_retention_days, same units."
  type        = number
  default     = 30
}

# -----------------------------------------------------------------------------
# Workload identity contributions
# -----------------------------------------------------------------------------

variable "k8s_namespace" {
  description = "Kubernetes namespace the card-vault workload runs in. Half of the OKE workload identity tuple (cluster, namespace, service account). Default matches the GCP module's."
  type        = string
  default     = "locker"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account the card-vault pod runs as. The other half of the workload identity tuple, and a hard security boundary: a grant without this condition authorises EVERY pod in the namespace. VERIFY IT AGAINST THE DEPLOYED CHART before relying on the default - the chart GCP deployed hardcodes its service-account name with no serviceAccount.create toggle (check sheet open question 9.5), so this may not be a free variable in practice."
  type        = string
  default     = "locker"
}

variable "workload_grant_compartment_id" {
  description = "Compartment the workload grants are scoped to, if narrower than compartment_id. Must be at or below the compartment the shared workload-identity policy is attached to, or the grant is unreachable. Defaults to compartment_id."
  type        = string
  default     = null
}

variable "grant_workload_key_usage" {
  description = "Emit a `use keys` grant scoped to this module's own key, the analogue of the AWS locker_kms policy. OFF by default: hyperswitch-card-vault compiles only the kms-aws and kms-hashicorp-vault features, so there is no confirmed way for the running application to use an OCI key, and an unusable grant is exactly the kind of surplus permission this port is meant to remove. See identity.tf and check sheet open question 9.5."
  type        = bool
  default     = false
}
