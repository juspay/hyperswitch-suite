# =============================================================================
# General configuration
# =============================================================================

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string

  validation {
    condition     = contains(["dev", "integ", "prod", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, integ, prod, sandbox"
  }
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "hyperswitch"
}

variable "compartment_id" {
  description = "OCID of the compartment topics and subscriptions are created in. Replaces AWS's implicit per-account scoping."
  type        = string

  validation {
    condition     = startswith(var.compartment_id, "ocid1.compartment.") || startswith(var.compartment_id, "ocid1.tenancy.")
    error_message = "compartment_id must be a compartment or tenancy OCID (ocid1.compartment... or ocid1.tenancy...)."
  }
}

variable "region" {
  description = "OCI region identifier (e.g. ap-mumbai-1). Output-only - an ONS topic exposes no region attribute."
  type        = string
}

# Topic names are unique within a compartment. Prefixed so two environments
# sharing a compartment (or a future move to a flatter compartment layout) do
# not collide. AWS gets this for free from the account boundary.
variable "topic_name_prefix" {
  description = "Prefix prepended to every topic key to form its ONS topic name (null derives \"<project>-<env>-\")"
  type        = string
  default     = null
}

# =============================================================================
# Topics and their subscriptions
# =============================================================================

variable "topics" {
  description = <<-EOT
    Map of topic key to configuration, with subscriptions nested - the same
    nested-map shape as the AWS module, which flattens topic x subscription pairs
    into one resource map. That flattening ports unchanged (see locals.tf).

    Deliberately ABSENT compared with the AWS surface, each a recorded gap:
      - fifo_topic / content_based_deduplication
                              feature 2, NONE. No ordering or dedup concept
                              exists for ONS topics. Unset on AWS today.
      - kms_master_key_id     feature 3, NONE. No CMEK argument on the topic.
                              Unset on AWS today.
      - policy                feature 6, NONE pending check sheet open question
                              1 - unlike file-storage and container-registry, no
                              compartment-level IAM substitute was confirmed for
                              topic publish/subscribe verbs, so none is offered
                              here rather than guessed at. Unset on AWS today.
      - data_protection_policy
                              feature 7, NONE, EXPLICIT DROP. See main.tf.
  EOT

  type = map(object({
    name        = optional(string)
    description = optional(string)

    subscriptions = optional(map(object({
      protocol = string
      endpoint = string

      # Optional per-subscription compartment. Rarely useful; defaults to the
      # topic's.
      compartment_id = optional(string)

      # SCHEMA CORRECTION vs. the check sheet. The sheet recorded
      # `delivery_policy` as computed/read-only on oci_ons_subscription. Against
      # the oracle/oci 9.0.0 schema it is optional+computed, i.e. settable - a
      # JSON string carrying backoff retry configuration. Exposed here because it
      # exists, which narrows (but does not close) feature 5: filter_policy,
      # raw_message_delivery and redrive_policy still have no counterpart.
      delivery_policy = optional(string)

      freeform_tags = optional(map(string), {})
      defined_tags  = optional(map(string), {})
    })), {})

    freeform_tags = optional(map(string), {})
    defined_tags  = optional(map(string), {})
  }))

  default = {}

  # Full allowed set from the ONS API. EMAIL is the only protocol any AWS live
  # root uses today. PAGERDUTY and SLACK are native here with no SNS
  # counterpart - a capability the port makes newly available (check sheet open
  # question 4), not one it needs.
  #
  # Two SNS protocols have NO entry in this list and cannot be ported: `sqs`
  # (queue fan-out is not a Notifications concept; OCI Queue is the product for
  # that) and `lambda` (ORACLE_FUNCTIONS is the nearest analogue and is listed).
  validation {
    condition = alltrue([
      for tk, tv in var.topics : alltrue([
        for sk, sv in coalesce(tv.subscriptions, {}) :
        contains(["CUSTOM_HTTPS", "EMAIL", "HTTPS", "ORACLE_FUNCTIONS", "PAGERDUTY", "SLACK", "SMS"], sv.protocol)
      ])
    ])
    error_message = "subscription protocol must be one of CUSTOM_HTTPS, EMAIL, HTTPS, ORACLE_FUNCTIONS, PAGERDUTY, SLACK, SMS. Note there is no SQS or Lambda equivalent - see variables.tf."
  }
}

# =============================================================================
# Tagging
# =============================================================================

variable "freeform_tags" {
  description = "Freeform tags merged onto every topic and subscription (AWS `tags` analogue)"
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags (namespace.key = value). Requires the tag namespace to already exist in the tenancy."
  type        = map(string)
  default     = {}
}
