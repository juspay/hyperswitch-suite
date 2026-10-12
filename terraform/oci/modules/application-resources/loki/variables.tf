# =============================================================================
# loki - the OCI port of application-resources/loki
# =============================================================================
# Check sheet: docs/multi-cloud-parity/oci/modules/loki.md
# Identity:    docs/multi-cloud-parity/oci/identity-model.md
# Network:     docs/multi-cloud-parity/oci/network-security-model.md (Option A)
#
# The narrowest module in the observability trio: one cluster, one namespace,
# one service account, one grant. Its whole job is a chunk bucket and the
# identity that reads and writes it, plus an ingress boundary for the query
# path.
#
# THIS MODULE CREATES NO `oci_identity_policy`. See locals.tf.
# =============================================================================

# -----------------------------------------------------------------------------
# Identity and placement
# -----------------------------------------------------------------------------

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
  description = "OCIDs of every OKE cluster whose workloads this grant authorises. A list from day one - N clusters means N statements, not N policy objects (identity-model.md section 5 Option A)."
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
  description = "Kubernetes namespace Loki runs in. Flattened to a scalar from AWS's `cluster_service_accounts` map values: one instantiation, one (namespace, service account) pair."
  type        = string
  default     = "loki"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name. NOTE: nothing annotates this service account on OCI. The POLICY names it; the pod side is `serviceAccountName` plus `automountServiceAccountToken: true` and nothing else - no `eks.amazonaws.com/role-arn` equivalent exists."
  type        = string
  default     = "loki"
}

# -----------------------------------------------------------------------------
# Chunk bucket (check sheet features 3 and 4)
# -----------------------------------------------------------------------------

variable "create_bucket" {
  description = "Create the chunk bucket. AWS: `module.s3_bucket` (`terraform-aws-modules/s3-bucket/aws ~>5.0`), `create = true` in the one live unit reviewed."
  type        = bool
  default     = true
}

variable "bucket_name" {
  description = "Chunk bucket name. Defaults to `<env>-<project>-loki-chunks`. OCI bucket names are unique within the tenancy's Object Storage namespace, not globally across the cloud as S3's are."
  type        = string
  default     = null
}

variable "bucket_lifecycle_expiry_days" {
  description = <<-EOT
    Days after which a chunk object is deleted. The direct translation of the
    live AWS unit's `lifecycle_rule = [{expiration.days = 365}]`, rendered as an
    `oci_objectstorage_object_lifecycle_policy` rule (`action = "DELETE"`,
    `time_unit = "DAYS"`) - a SEPARATE resource on OCI rather than an inline
    block on the bucket.

    365 is the value in the ONE live unit this port's check sheet read. Whether
    sandbox and prod use the same figure was not confirmed; if they differ, this
    belongs in stack `values` rather than being taken as a constant (check sheet
    section 9 Q3). Null emits no lifecycle policy.
  EOT
  type        = number
  default     = 365
}

variable "bucket_versioning_enabled" {
  description = "Bucket versioning. Disabled by default: unlike `vector`, the live loki unit sets no versioning toggle, and this port does not invent one it has no evidence for. Chunks are immutable and expire on a schedule; versioning would double the storage the lifecycle rule exists to bound."
  type        = bool
  default     = false
}

variable "bucket_storage_tier" {
  description = "Object Storage tier for the chunk bucket."
  type        = string
  default     = "Standard"
}

# -----------------------------------------------------------------------------
# Ingress boundary (check sheet feature 6, FULL - but the rules move phase)
# -----------------------------------------------------------------------------

variable "create_nsg" {
  description = <<-EOT
    Create the module-owned Network Security Group for Loki's query-path load
    balancer. Replaces AWS's `create_security_group` (true, exercised, in the
    one live unit).

    CREATED EMPTY, ON PURPOSE - see network.tf. This is the same contract the
    `database` and `oci-cache-valkey` modules already use: this module owns the
    NSG object and exports its OCID; `composition/security-rules`, running in
    the last stack phase, writes the rules into it.
  EOT
  type        = bool
  default     = true
}

variable "vcn_id" {
  description = "OCID of the VCN the NSG is created in. Required when `create_nsg` is true - an `oci_core_network_security_group` is a VCN-scoped object, unlike an AWS security group which only needs a VPC id at creation."
  type        = string
  default     = null
}

variable "nsg_display_name" {
  description = "Display name for the module-owned NSG. Defaults to `<env>-<project>-loki-nsg`."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Escape hatches
# -----------------------------------------------------------------------------

variable "shared_statements" {
  description = <<-EOT
    Statement strings contributed from a shared source, appended to
    `policy_statements`. Replaces `customer_managed_policy_arns` /
    `aws_managed_policy_names` (check sheet feature 2, SUBSTITUTE - nothing is
    attachable on OCI; `shared-policy` becomes a statement-text factory,
    identity-model.md section 3.6).

    NO LIVE CALLER. The one catalog unit reviewed sets neither AWS variable.
    Present for parity, and recorded so a future caller does not assume AWS's
    attach-by-ARN semantics survived the port.
  EOT
  type        = list(string)
  default     = []
}

variable "extra_statements" {
  description = "Free-form statement strings appended to `policy_statements`. Write them pre-normalised and use `in compartment id <ocid>`, never `in compartment <name>`."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

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
