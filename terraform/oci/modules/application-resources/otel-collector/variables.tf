# otel-collector - the OCI port of the AWS module of the same name.
# THE KEY DIFFERENCE: OCI SPLITS THE AWS MODULE'S ONE IDENTITY INTO THREE:
#   metrics -> OCI Monitoring  `use metrics`      IAM / workload identity
#   logs    -> OCI Logging     `use log-content`  IAM / workload identity
#   TRACES  -> OCI APM         NOT IAM AT ALL - `Authorization: dataKey` header.
# So `AWSXRayDaemonWriteAccess` has NO IAM counterpart; `use apm-domains`
# governs MANAGING domains, not uploading. THIS MODULE CREATES NO
# `oci_identity_policy` - it renders statements for the shared object and owns
# the two observability backends AWS never had to configure.
# CONSEQUENCE (unresolved oracle gate): a long-lived data key is not rotated by
# anything automatic - it needs an owner and a rotation interval.

variable "compartment_id" {
  description = "OCID of the environment compartment. Default location term in rendered statements, default home for the APM domain and log group, and the attachment point of the consuming shared policy object. Replaces AWS `region` + the implicit account: neither is part of an OCI IAM grant."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID."
  }
}

variable "cluster_ids" {
  description = "OCIDs of every OKE cluster running a collector this identity serves. A list from day one - the policy name is tenancy-unique and non-updatable. Two live roots racing for the same name is an apply-time failure; here it degrades observability rather than the platform, which means it is discovered during an incident, when telemetry is what you need."
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
  description = "Namespace the collector runs in. Flattened from `cluster_service_accounts` to a scalar - every live root passes exactly one pair."
  type        = string
  default     = "monitoring"
}

variable "k8s_service_account_name" {
  description = "Service account the collector pod runs as. Nothing annotates it on OCI."
  type        = string
  default     = "otel-collector"
}

variable "metrics_namespace" {
  description = <<-EOT
    Metric namespace the collector publishes into. When set, every `use metrics`
    statement carries `target.metrics.namespace='<value>'`.

    A GENUINE IMPROVEMENT OVER AWS, and the reason this is not just plumbing:
    CloudWatch's PutMetricData cannot be constrained to a namespace by IAM in
    this way. Leave it null only if you actually want the collector able to
    publish into any namespace in the compartment.

    OPEN (check sheet question 5): whether PostMetricData creates a namespace
    implicitly or the namespace must pre-exist was not confirmed. If it must
    pre-exist, that is another resource this module would own.
  EOT
  type        = string
  default     = null
}

variable "enable_metrics_grant" {
  description = "Emit `use metrics` (METRIC_WRITE / PostMetricData). True by default. Set false only if metrics go to APM via OTLP with the data key instead of to OCI Monitoring - doing both duplicates data and cost (check sheet question 2). If both this and enable_logs_grant are false this module contributes NO statements at all, and the collector's only credential is the APM data key."
  type        = bool
  default     = true
}

variable "enable_logs_grant" {
  description = "Emit `use log-content` (LOG_CONTENT_PUSH). True by default. `use log-content` grants the verb but there must be a TARGET - see create_log_group. OPEN (check sheet question 1): whether OCI APM accepts an OTLP logs signal at all; the APM configuration page documents spans and metrics endpoints only, which is why this module assumes logs go to OCI Logging."
  type        = bool
  default     = true
}

variable "logs_compartment_id" {
  description = "Compartment the `use log-content` grant is scoped to, and where the log group is created. Defaults to compartment_id."
  type        = string
  default     = null

  validation {
    condition     = var.logs_compartment_id == null || can(regex("^ocid1\\.(compartment|tenancy)\\.", var.logs_compartment_id))
    error_message = "logs_compartment_id must be a compartment or tenancy OCID."
  }
}

variable "metrics_compartment_id" {
  description = "Compartment the `use metrics` grant is scoped to. Defaults to compartment_id."
  type        = string
  default     = null

  validation {
    condition     = var.metrics_compartment_id == null || can(regex("^ocid1\\.(compartment|tenancy)\\.", var.metrics_compartment_id))
    error_message = "metrics_compartment_id must be a compartment or tenancy OCID."
  }
}

# =============================================================================
# APM - the trace backend. NONE of this produces an IAM grant.
# =============================================================================

variable "create_apm_domain" {
  description = <<-EOT
    Create an `oci_apm_apm_domain` and export its data upload endpoint.

    SCOPE CREEP BY NECESSITY, and an oracle gate item (check sheet section 8
    item 4), NOT CONSULTED. On AWS this module is an identity and nothing else,
    because X-Ray needs no configuration. Here the trace backend is an explicit
    object with an explicit regional endpoint, so either this module owns it or
    a separate `oci-apm` unit does - which moves the dependency without moving
    the coupling.

    OPEN (check sheet question 6): APM domains are REGIONAL and the data upload
    endpoint is region-specific, while compartments are global. A cluster in one
    region exporting to a domain in another cross-region-egresses every span.
  EOT
  type        = bool
  default     = false
}

variable "apm_domain_id" {
  description = "OCID of a PRE-EXISTING APM domain, used when create_apm_domain is false. Mutually exclusive with it."
  type        = string
  default     = null
}

variable "apm_domain_display_name" {
  description = "Display name for the created APM domain. Null uses '<project>-<env>-otel-apm'."
  type        = string
  default     = null
}

variable "apm_is_free_tier" {
  description = "Create the APM domain on the always-free tier. Appropriate for dev; a deliberate capacity decision anywhere else."
  type        = bool
  default     = false
}

variable "apm_data_key_secret_id" {
  description = <<-EOT
    OCID of the OCI Vault secret holding the APM PRIVATE DATA KEY. Passed
    straight through to the output the collector configuration consumes; the key
    VALUE never enters Terraform.

    THIS MODULE DELIBERATELY DOES NOT READ THE KEY. `data "oci_apm_data_keys"`
    exists and would return it - and would write it to Terraform state in
    plaintext. Note the key is not an attribute of `oci_apm_apm_domain` either,
    which is why creating the domain here is safe. The intended flow is: create
    the domain in Terraform, have a human or a bootstrap job place the private
    key into the vault once, and reference the SECRET by OCID from here so
    external-secrets-operator projects it into the `monitoring` namespace.

    Check sheet question 3 asks whether any Terraform path can obtain the key
    without state exposure. Until it is answered, the answer here is "do not
    try".
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.apm_data_key_secret_id == null || can(regex("^ocid1\\.vaultsecret\\.", var.apm_data_key_secret_id))
    error_message = "apm_data_key_secret_id must be a Vault secret OCID (ocid1.vaultsecret.*). It is the OCID of the SECRET, never the key material."
  }
}

# =============================================================================
# OCI Logging - the log push target
# =============================================================================

variable "create_log_group" {
  description = "Create an `oci_logging_log_group` and a CUSTOM `oci_logging_log` for the collector to push into. `use log-content` grants the verb; without a target there is nothing to push to. New surface with no AWS counterpart - on AWS the collector's log destination is configured downstream."
  type        = bool
  default     = false
}

variable "log_group_id" {
  description = "OCID of a pre-existing log group, used when create_log_group is false."
  type        = string
  default     = null
}

variable "log_display_name" {
  description = "Display name for the created custom log. Null uses '<project>-<env>-otel-collector'."
  type        = string
  default     = null
}

variable "log_retention_duration" {
  description = "Retention in days for the created custom log. OPEN (check sheet question 4): the AWS side sets no retention here, so there is no value to port - this is a new decision, not a translation. 30 mirrors the OCI service default."
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_duration >= 30 && var.log_retention_duration <= 180
    error_message = "log_retention_duration must be between 30 and 180 days (OCI Logging's accepted range)."
  }
}

# =============================================================================
# Escape hatches
# =============================================================================

variable "additional_grants" {
  description = "Extra grants in `oke-workload-identity`'s grant shape. Replaces AWS `inline_policies` (`map(object({name, policy}))`): a grant is a verb + resource-type + location + condition, and a JSON policy document has no counterpart. If the collector self-configures via the unified agent path it needs `read unified-configuration` here; an OTLP-only deployment does not."
  type = list(object({
    verb           = string
    resource_type  = string
    compartment_id = optional(string)
    condition      = optional(string)
  }))
  default = []

  validation {
    condition     = alltrue([for g in var.additional_grants : contains(["inspect", "read", "use", "manage"], lower(trimspace(g.verb)))])
    error_message = "additional_grants[*].verb must be one of inspect, read, use, manage."
  }
}

variable "shared_statements" {
  description = "Statements from the `shared-policy` module. Replaces `customer_managed_policy_arns`, which no live root sets. Nothing is attachable on OCI, so a shared grant costs one statement per consuming policy rather than one attachment, and revocation becomes a fan-out apply."
  type        = list(string)
  default     = []
}

variable "extra_statements" {
  description = "Raw statement strings appended verbatim. Replaces `additional_assume_role_statements`."
  type        = list(string)
  default     = []
}

variable "cross_tenancy_enabled" {
  description = "Informational only, and false everywhere today. Replaces the AWS `assume_role_principals` feature flag (`[]` in every live root). Cross-tenancy workload principals are undocumented (see argocd.md section 4.3); the APM domain and log groups live in the same environment's compartments, so there is no cross-tenancy path in the current design. It becomes load-bearing only if observability is later centralised into a separate tenancy."
  type        = bool
  default     = false
}

variable "project_name" {
  description = "Project name for naming and tags."
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment short name. NOTE the AWS default name here was <environment>-<project>-<app>-role - environment FIRST, unlike external-secrets-operator's project-first. The OCI convention is <project>-<env>-<app>, which reorders this module's historical name. One order everywhere beats two modules disagreeing about what a policy is called."
  type        = string
}

variable "region" {
  description = "Region identifier. Not part of any IAM grant. Retained because it tags resources and because the APM data upload endpoint is regional."
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Freeform tags, merged over the module's own."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "OCI defined tags, keyed \"namespace.key\"."
  type        = map(string)
  default     = {}
}
