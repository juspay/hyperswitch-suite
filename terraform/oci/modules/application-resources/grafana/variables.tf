# grafana - OCI Database-backed dashboards with observability-data grants.
# 84 AWS variables collapse to roughly 20, the reduction coming from folding
# database.md's mapping into ONE `database_config` object. It creates no
# `oci_identity_policy` - see locals.tf.

variable "compartment_id" {
  description = "OCID of the compartment this module's resources live in, and the location term of every statement it renders. Must be at or below the compartment the shared `oke-workload-identity` policy is attached to."
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

variable "k8s_namespace" {
  description = "Kubernetes namespace Grafana runs in. Flattened to a scalar from AWS's `cluster_service_accounts` map values."
  type        = string
  default     = "monitoring"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name. Nothing annotates it on OCI: the POLICY names it, and the pod side is `serviceAccountName` plus `automountServiceAccountToken: true`."
  type        = string
  default     = "grafana"
}

variable "metrics_read_enabled" {
  description = <<-EOT
    Grant `read metrics` so Grafana's OCI Monitoring datasource can query metric
    data. Replaces half of the AWS unit's
    `aws_managed_policy_names = ["AWSXrayReadOnlyAccess",
    "CloudWatchReadOnlyAccess"]` - two named managed-policy strings become two
    booleans, because there is no managed-policy object to name, only verbs to
    grant.

    NOTE THE VERB. `read metrics` is METRIC_INSPECT + METRIC_READ. It is NOT
    `use metrics`, which is METRIC_WRITE and is what a PUBLISHER like
    `otel-collector` needs. The publish side is the only direction most modules
    need; the read verbs were verified while porting this module.
  EOT
  type        = bool
  default     = true
}

variable "logs_read_enabled" {
  description = <<-EOT
    Grant `read log-content` (LOG_CONTENT_READ, `ListSearchLogs`) AND
    `read log-groups` (LOG_GROUP_READ) so Grafana's OCI Logging datasource can
    search logs and enumerate which log groups exist for its picker. TWO
    statements, not one - the search verb does not imply the enumeration verb.

    Again note the verb: `read log-content`, not `use log-content`, which is
    LOG_CONTENT_PUSH and belongs to a shipper.
  EOT
  type        = bool
  default     = true
}

variable "datasource_api_key_vault_secret_id" {
  description = <<-EOT
    OCID of an OCI Vault secret holding a User Principal API-key configuration
    for Oracle's Grafana datasource plugins. THE FALLBACK PATH, AND AN ACCEPTED
    REGRESSION IF USED.

    The DATA path here is not a gap: OCI Monitoring and OCI Logging are
    queryable, Oracle maintains `oci-metrics-datasource` and
    `oci-logs-datasource` on the Grafana marketplace, and the three IAM grants
    above are ordinary workload-identity statements with no architectural
    obstacle.

    The IDENTITY path is the gap. Both plugins' documentation describes exactly
    two supported authentication modes: Instance Principal (a dynamic group over
    compute instances, plus a tenancy-root policy) and User Principal (a local
    API-key file). NEITHER NAMES WORKLOAD IDENTITY - though both are OCI-Go-SDK
    based and the SDK has supported workload identity for a long time, so whether the binary implements the code path is
    undocumented rather than known-absent (answerable by reading the
    auth-provider selection code in github.com/oracle/oci-grafana-metrics).

    RANKED OUTCOMES:
      1. If the plugin does honour workload identity, wire it that way and leave
         this null. Zero exception.
      2. If not, a vaulted, rotated User Principal API key, relayed by
         external-secrets-operator - the same shape `vector`'s Kafka auth token
         and `otel-collector`'s APM data key already take. This variable.
      3. REJECTED: a dedicated dynamic group over Grafana's own node pool. It
trades a credential file for instance-principal access, which is the
          mechanism whose blast radius is largest
         in detail, for a workload with no functional need to touch anything
         else on that node.

    Only the OCID is accepted. This module never reads, stores or emits a
    credential value, and creates no user and no API key. Setting it flips
    `datasource_uses_static_credential` so the regression appears in the plan.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.datasource_api_key_vault_secret_id == null || can(regex("^ocid1\\.vaultsecret\\.", var.datasource_api_key_vault_secret_id))
    error_message = "datasource_api_key_vault_secret_id must be an OCI Vault secret OCID (ocid1.vaultsecret.*). It must never be a credential value."
  }
}

variable "shared_statements" {
  description = "Statement strings contributed from a shared source. Replaces `customer_managed_policy_arns` / any `aws_managed_policy_names`. Nothing is attachable on OCI. No live caller today."
  type        = list(string)
  default     = []
}

variable "extra_statements" {
  description = "Free-form statement strings appended to `policy_statements`. Write them pre-normalised and use `in compartment id <ocid>`."
  type        = list(string)
  default     = []
}

variable "create_database" {
  description = <<-EOT
    Provision Grafana's own PostgreSQL database (dashboards, users, alert
    rules), nested inside this module - exactly as the AWS module nests
    `composition/database` rather than depending on the shared platform
    database. Live AWS setting: true.

    ONE CONSEQUENCE, stated because it looks like a phasing bug and is not: a
    nested database provisions in stack phase 3 alongside Grafana, not in phase
    1 with the standalone `database` unit. Identical to AWS today.
  EOT
  type        = bool
  default     = false
}

variable "database_config" {
  description = <<-EOT
    Passed straight through to the nested `composition/database` module.

    TWO THINGS GRAFANA'S OWN CONFIGURATION HAS TO CHANGE BECAUSE OF THIS, and
    neither is a Terraform input:

      1. TLS IS MANDATORY AND CANNOT BE TURNED OFF. OCI Database with PostgreSQL
         permits only `hostssl` entries in pg_hba.conf - "non-SSL connections
         are not supported due to regulatory and compliance requirements" - and
         the TLS protocol parameters are read-only. So `GF_DATABASE_SSL_MODE`
         must be `require`, `verify-ca` or `verify-full`, never `disable`, and
         for verify-* the `database_ca_certificate` output has to be mounted
         into the pod. Set this in the Helm values BEFORE applying, not after:
         discovered at apply time it surfaces as a generic connection error, not
         an obviously TLS-shaped one.

      2. There is no per-app database. OCI creates only the default `postgres`
         database and provider 9.0.0 has no `oci_psql_database` resource, so a
         `grafana` database is a manual `psql` step. GCP's AlloyDB port hit the
         identical wall (database.md open question 9.4).

    DELIBERATELY ABSENT: every cross-region-DR field. See
    `enable_warm_standby` below and the note on it.
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
    admin_username              = optional(string, "grafana")
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
    query_insights_enabled = optional(bool, true)
    enable_service_logs    = optional(bool, true)
    log_retention_duration = optional(number, 30)
  })
  default = {}
}

variable "host_domains" {
  description = "DNS/ingress metadata, echoed unchanged as `host_domains_map`. No cloud resource behind it on any cloud; trivially portable, and the GCP precedent has the identical output."
  type        = map(string)
  default     = {}
}

variable "freeform_tags" {
  description = "Freeform tags merged onto every resource."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags, keyed \"namespace.key\". Passed through untouched."
  type        = map(string)
  default     = {}
}
