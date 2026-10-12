# vector - OCI port of application-resources/vector (one instantiation per log stream)

variable "compartment_id" {
  description = "OCID of the compartment this module's resources live in, and the default location term of every statement it renders. Must be at or below the compartment the shared `oke-workload-identity` policy is attached to."
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

variable "app_name" {
  description = <<-EOT
    Logical log-stream name - `vector-logging`, `vector-dr`,
    `vector-dr-consumer`, `vector-hyperswitch-art`, `vector-ucs-deja`. Used in
    bucket, stream and NSG naming, exactly as the AWS module's `app_name` is.

    THIS IS WHAT MAKES FIVE INSTANTIATIONS DISTINCT. AWS has five separate
    roles today; this port keeps five separate statement sets rather than
    merging them into one shared "vector" identity - a merge would be a real
    architectural change with no AWS evidence behind it, and would give all five
    streams each other's bucket access. (Check sheet section 4.1; that
    keep-separate call is an oracle gate item, section 8 item 3, NOT YET
    CONSULTED.)
  EOT
  type        = string
  default     = "vector"
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
  description = "Kubernetes namespace this log stream's pods run in. Flattened to a scalar from AWS's `cluster_service_accounts` map values - one instantiation, one pair."
  type        = string
  default     = "vector"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name, e.g. `vector-logging`. Nothing annotates it: the POLICY names it, and the pod side is `serviceAccountName` plus `automountServiceAccountToken: true`."
  type        = string
}

variable "create_bucket" {
  description = "Create this stream's own log bucket. AWS: `module.s3_bucket`, `s3.create = true` in the `vector-dr` unit."
  type        = bool
  default     = true
}

variable "bucket_name" {
  description = "Log bucket name. Defaults to `<env>-<project>-<app_name>`. OCI bucket names are unique within the tenancy's Object Storage namespace, not globally as S3's are."
  type        = string
  default     = null
}

variable "bucket_versioning_enabled" {
  description = "Bucket versioning. AWS's `s3.versioning` is a real toggle on this module, so it survives as one - unlike `loki`, which has no versioning setting in its live unit."
  type        = bool
  default     = false
}

variable "bucket_storage_tier" {
  description = "Object Storage tier for the log bucket."
  type        = string
  default     = "Standard"
}

variable "bucket_lifecycle_rules" {
  description = <<-EOT
    Lifecycle rules on the log bucket. A SEPARATE resource on OCI
    (`oci_objectstorage_object_lifecycle_policy`), not an inline block on the
    bucket - structural difference, not a capability gap.

    `action` is one of DELETE / ARCHIVE / INFREQUENT_ACCESS / ABORT. AWS's
    storage-class transitions map onto ARCHIVE / INFREQUENT_ACCESS; expiration
    maps onto DELETE.
  EOT
  type = list(object({
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
  }))
  default = []
}

variable "bucket_read_only" {
  description = <<-EOT
    Grant `read objects` instead of `manage objects` on this stream's bucket.

    For CONSUMER-ONLY instantiations (`vector-dr-consumer`), which read objects
    another stream wrote and never write themselves. Producers must leave this
    false: `PutObject` needs OBJECT_CREATE, which only `manage` grants
    (identity-model.md section 3.5).
  EOT
  type        = bool
  default     = false
}

variable "create_notification" {
  description = <<-EOT
    Build the new-object-signal pipeline. AWS: `sqs.create = true` -
    `aws_sqs_queue` + `aws_sqs_queue_policy` + `aws_s3_bucket_notification`.

    THE TARGET SERVICE CHANGED, NOT JUST THE RESOURCE NAMES.
    `oci_events_rule.actions.action.action_type` accepts exactly ONS, OSS and
    FAAS - the OCI QUEUE SERVICE IS NOT A VALID EVENTS TARGET. So the pipeline
    is Object Storage event -> Events rule -> STREAMING stream, consumed by
    Vector's `kafka` source, not its `aws_s3`/SQS source. Vector's ingestion
    config for these streams changes source TYPE, not just endpoint.

    Read notification.tf before enabling this. It carries the one documented
    exception to the platform's identity model, and four delivery-semantics
    changes (redelivery unit, retention ceiling, dead-letter handling, ordering)
    that are not configuration differences.
  EOT
  type        = bool
  default     = false
}

variable "stream_partitions" {
  description = <<-EOT
    Partitions on the Streaming stream.

    1 by default, and that default is a trade AWS never had to make. A single
    partition gives per-partition FIFO ordering - a genuine Kafka-log property
    SQS standard queues do not have - at the cost of capping consumer
    parallelism at one. Multiple partitions buy throughput and lose
    cross-partition order, which is what SQS standard already did.

    Check sheet section 8 item 2: an oracle gate item, NOT YET CONSULTED. Also
    section 9 Q3 - Streaming's per-partition throughput ceiling was not verified
    against this log volume; load-test before committing to 1 in prod.
  EOT
  type        = number
  default     = 1

  validation {
    condition     = var.stream_partitions >= 1
    error_message = "stream_partitions must be at least 1."
  }
}

variable "stream_retention_hours" {
  description = <<-EOT
    Stream retention, in hours. Capped at OCI's ceiling of 168 (7 days).

    A REAL REGRESSION, not a rename. The AWS module defaults
    `message_retention_seconds` to 1,209,600 - fourteen days, the SQS maximum.
    OCI Streaming's range is 24-168 hours, so the backlog headroom halves: a
    consumer down for more than a week loses history it would have kept on AWS.
    Check sheet section 8 item 6, oracle gate NOT YET CONSULTED.
  EOT
  type        = number
  default     = 168

  validation {
    condition     = var.stream_retention_hours >= 24 && var.stream_retention_hours <= 168
    error_message = "stream_retention_hours must be between 24 and 168. OCI Streaming cannot hold 14 days of backlog even if asked to - AWS's SQS default of 14 days has no OCI equivalent."
  }
}

variable "stream_pool_id" {
  description = <<-EOT
    OCID of an existing Streaming stream pool to place the stream in. Null uses
    the tenancy's default pool.

    Relevant because the SASL username the Kafka client needs is
    `<tenancy-name>/<username>/<stream-pool-OCID>` - the pool OCID is part of
    the credential, not just placement. A private stream pool is also the only
    way to keep the Kafka endpoint off the public internet, which matters for
    the cross-region case (check sheet section 4.5).
  EOT
  type        = string
  default     = null
}

variable "event_types" {
  description = "Object Storage event types the rule matches. The direct translation of AWS's `s3:ObjectCreated:*`."
  type        = list(string)
  default     = ["com.oraclecloud.objectstorage.createobject"]
}

variable "event_object_name_prefix" {
  description = "Optional object-name prefix filter on the Events rule. The `filter_prefix` analogue from AWS's `s3.event_notifications`."
  type        = string
  default     = null
}

variable "auth_token_vault_secret_id" {
  description = <<-EOT
    OCID of the OCI Vault secret holding the Kafka SASL/PLAIN auth token used to
    consume the Streaming stream.

    THIS IS THE ONE DOCUMENTED EXCEPTION TO THE PLATFORM'S IDENTITY MODEL, AND
    IT IS DELIBERATE. Read all of it.

    OCI Streaming's Kafka-compatible endpoint authenticates with SASL/PLAIN
    only: security protocol SASL_SSL, mechanism PLAIN, username
    `<tenancy-name>/<username>/<stream-pool-OCID>`, password an OCI AUTH TOKEN.
    An auth token is generated in the Console, bound to an OCI USER, viewable
    once, and is not tied to workload identity, an instance principal, or any
    `request.principal.*` condition at all. There is no workload-identity path
    to this endpoint. Vector's `kafka` source supports exactly this shape and no
    other, and Vector has no `oci_object_storage` source to fall back on.

    So consuming the event pipeline cannot be done under pure workload identity.
    That is a fact about the two products, not a shortcut taken here.

    HOW THE EXCEPTION IS BOUNDED:
      * The token is NEVER a literal and never an input to this module. Only the
        OCID of a Vault secret is accepted; this module does not read, store or
        emit the token value, and it does not create an `oci_identity_user`,
        an `oci_identity_auth_token` or an `oci_vault_secret`. An operator mints
        those out of band, deliberately.
      * Mint a DEDICATED, least-privilege OCI user for this consumption alone.
        Auth tokens authenticate as the whole user everywhere that user has
        grants (check sheet section 9 Q2, unverified) - so a shared user is the
        difference between a bounded credential and a wide one.
      * Project it into the pod with `external-secrets-operator`, which itself
        runs under workload identity - the same relay `otel-collector` uses for
        its APM data key.
      * Put an owner and a rotation interval on it.

    THE ALTERNATIVE, if the gate rejects the exception: drop the event pipeline
    (`create_notification = false`) and poll Object Storage directly under pure
    workload identity - the `read`/`manage objects` grant is already there.
    Zero static credentials, at the cost of poll-interval latency instead of
    push, and custom code instead of configuration. Check sheet section 4.4
    option 2.

    Check sheet section 8 item 1 calls this the highest-value gate item in the
    loki/vector/grafana trio. NOT YET CONSULTED.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.auth_token_vault_secret_id == null || can(regex("^ocid1\\.vaultsecret\\.", var.auth_token_vault_secret_id))
    error_message = "auth_token_vault_secret_id must be an OCI Vault secret OCID (ocid1.vaultsecret.*). It must NEVER be the token value itself - this module does not accept, read or store credentials."
  }
}

variable "kafka_sasl_username" {
  description = <<-EOT
    Username half of the SASL/PLAIN credential, if it should be rendered by this
    module rather than assembled by the consumer. Format is
    `<tenancy-name>/<oci-username>/<stream-pool-OCID>` - note TENANCY NAME, not
    tenancy OCID.

    Not a secret (the password is), but supplied rather than derived because
    this module knows the stream pool OCID and nothing else in the triple. Left
    null, the `kafka_connection` output carries the pool OCID and the endpoint
    and leaves the username to the caller.
  EOT
  type        = string
  default     = null
}

variable "cross_region_read" {
  description = <<-EOT
    Read another region's bucket and stream without creating anything locally.
    AWS: `aws_iam_policy.sqs_cross_region_policy`.

    PARTIAL, and the missing part is not IAM. On GCP this is genuinely just an
    IAM grant, because Pub/Sub is a GLOBAL service. OCI Streaming is REGIONAL:
    each stream's messages endpoint lives in one region, and a private stream
    pool is reachable only from inside its own subnet. So the grants below are
    necessary and not sufficient - a network path (public TLS endpoint, or a DRG
    to the primary region's VCN) has to be decided separately, and this module
    has no slot for that decision. AWS needed none, because SQS queues have
    public regional endpoints.

    `kms_key_arn` has no counterpart: there is no customer-managed key on the
    Object Storage side to decrypt with.

    Check sheet section 4.5 and section 8 item 5, oracle gate NOT YET CONSULTED.
  EOT
  type = object({
    enabled                  = optional(bool, false)
    bucket_compartment_id    = optional(string)
    bucket_name              = optional(string)
    stream_compartment_id    = optional(string)
    stream_messages_endpoint = optional(string)
  })
  default = {}
}

variable "shared_statements" {
  description = <<-EOT
    Statement strings contributed from a shared source. Replaces
    `customer_managed_policy_arns` / `aws_managed_policy_names` (check sheet
    feature 2, SUBSTITUTE - nothing is attachable on OCI).

    identity-model.md section 1.2's union-of-actions row for `vector` includes
    SNS publish and KMS decrypt, neither of which exists as a resource in this
    module - so at least one of the five instantiations attaches something
    beyond its own bucket and queue grants. On OCI those become
    `manage ons-topics` (or narrower) and `use keys` scoped to a Vault key,
    contributed here.

    Note the cost shape changes: a shared grant is one statement per contributing
    instantiation rather than one attachment, so revoking it is a fan-out edit
    across up to five callers rather than one detach call.
  EOT
  type        = list(string)
  default     = []
}

variable "extra_statements" {
  description = "Free-form statement strings appended to `policy_statements`. Write them pre-normalised and use `in compartment id <ocid>`."
  type        = list(string)
  default     = []
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
