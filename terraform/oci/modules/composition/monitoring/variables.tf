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

variable "region" {
  description = "OCI region identifier (e.g. ap-mumbai-1). Used in alarm naming and passed through as an output."
  type        = string
  default     = null
}

# Where the ALARM object lives.
variable "compartment_id" {
  description = "OCID of the compartment alarms, log groups and logs are created in"
  type        = string

  validation {
    condition     = startswith(var.compartment_id, "ocid1.compartment.") || startswith(var.compartment_id, "ocid1.tenancy.")
    error_message = "compartment_id must be a compartment or tenancy OCID (ocid1.compartment... or ocid1.tenancy...)."
  }
}

# Where the METRIC BEING EVALUATED lives. A distinction AWS never has to make:
# a CloudWatch alarm and the metric it watches are always in the same account
# and region. On OCI the alarm can sit in one compartment and read metrics
# emitted in another. null collapses the two, which is the flat first-cut layout.
variable "metric_compartment_id" {
  description = "OCID of the compartment the evaluated metrics are emitted in (null = same as compartment_id). No AWS counterpart."
  type        = string
  default     = null
}

variable "metric_compartment_id_in_subtree" {
  description = "Evaluate metrics across the metric compartment's descendants as well. No AWS counterpart."
  type        = bool
  default     = false
}

# =============================================================================
# Alarm notification routing (feature 7)
# =============================================================================
# Replaces AWS's `sns_topic_arns` map (severity -> ARN). Same keying, different
# value type: oci_monitoring_alarm.destinations is a REQUIRED list, and Oracle
# limits it to one destination per supported destination service (Notifications,
# Streaming). Combined with per-severity alarm splitting (feature 4), this
# reproduces AWS's severity-keyed routing exactly.
#
# AWS's ok_actions and insufficient_data_actions have NO counterpart: an OCI
# alarm has one destination list used for both firing and reset notifications,
# and there is no separate "insufficient data" action at all. See main.tf.

variable "destinations" {
  description = "Map of severity key (sev1, sev2, ...) to a list of destination OCIDs - ONS topic OCIDs from the `notifications` module. Replaces AWS's sns_topic_arns."
  type        = map(list(string))
  default     = {}
}

variable "default_destinations" {
  description = "Destination OCIDs used for a severity with no entry in var.destinations. `destinations` is required on every OCI alarm, so an alarm with no route cannot be created at all - unlike AWS, where an alarm with empty alarm_actions is legal and silently notifies nobody."
  type        = list(string)
  default     = []
}

# =============================================================================
# Classified multi-severity alarms (feature 4) - the module's dominant use
# =============================================================================
# 95 alarm definitions producing 203 resources in prod/us-east-1 alone. The AWS
# variable shape is preserved deliberately: whoever writes 95 entries of this per
# environment understands it, and forcing them to hand-write raw MQL strings
# instead would be a large migration cost for no benefit. The module renders MQL
# internally (locals.tf) from the same typed fields.

variable "dimension_map" {
  description = <<-EOT
    Flat map of named dimension sets, referenced by alarms via dimension_key.
    Identical mechanism and identical reason for existing as the AWS module's:
    build it at the top level of a terragrunt `inputs` block so `dependency.*`
    refs are legal there.

    OCI dimension VOCABULARY differs from AWS's - namespaces are `oci_computeagent`,
    `oci_database`, etc. rather than `AWS/EC2`, `AWS/RDS`, and dimension keys are
    `resourceId`/`resourceDisplayName` rather than `InstanceId`/`DBClusterIdentifier`.
    That is a per-metric remapping job for whoever ports the 95 alarm definitions,
    not a capability gap (check sheet feature 1, FULL).
  EOT
  type        = map(map(string))
  default     = {}
}

variable "classified_metric_alarms" {
  description = <<-EOT
    Map of classified metric alarms with multi-severity support. One
    oci_monitoring_alarm per (alarm, severity) pair - the same flattening the AWS
    module's `classified_alarms_flat` local already performs, ported unchanged,
    because destination routing is per-resource on both clouds.

    Each alarm MUST define at least sev1.

    Fields that exist on AWS and have NO OCI counterpart, dropped here rather
    than accepted and ignored - see main.tf for the full write-up:
      - treat_missing_data    OCI has no missing-data policy. MQL's absent()
                              function is a separate alarm, not a modifier.
      - datapoints_to_alarm   No M-of-N evaluation. pending_duration is a single
                              continuous window.
      - skip_ok_action        An OCI alarm notifies on RESET as well as FIRING and
                              there is no way to suppress only the reset.
  EOT

  type = map(object({
    classification = string
    metric_name    = string
    namespace      = string
    dimension_key  = optional(string, "")
    dimensions     = optional(map(string), {})

    # Seconds, as on AWS. Rendered into MQL's [interval] window.
    period = optional(number, 60)

    # AWS statistic names (Average, Sum, Minimum, Maximum, SampleCount) are
    # accepted and translated; MQL function names (mean, sum, min, max, count,
    # rate, percentile) pass through.
    statistic = optional(string, "Average")

    # Argument for statistics that take one, e.g. "0.9" with statistic =
    # "percentile". No AWS counterpart - AWS spells percentiles as the statistic
    # itself ("p90").
    statistic_argument = optional(string)

    # Optional MQL .groupBy(...) / .grouping() suffix, e.g. "groupBy(resourceId)".
    # No AWS counterpart.
    grouping = optional(string)

    resource_group = optional(string)

    # Escape hatch. When set, the module uses this MQL string verbatim for every
    # severity of this alarm and ignores metric_name/statistic/period/dimensions
    # AND the severity's threshold/comparison_operator. Exists because MQL is
    # strictly more expressive than the typed fields above in ways this module
    # does not attempt to model (join queries, absent(), rate()). Use sparingly:
    # a raw query bypasses every consistency guarantee the builder provides.
    query_override = optional(string)

    severities = map(object({
      threshold = number

      # AWS comparison-operator names (GreaterThanThreshold, ...) are accepted
      # and translated to MQL operators; MQL operators (>, >=, <, <=, ==, !=)
      # pass through.
      comparison_operator = optional(string, "GreaterThanThreshold")

      description = string

      # AWS's evaluation_periods x period becomes OCI's pending_duration, a
      # single ISO-8601 duration. Derived unless pending_duration is set.
      evaluation_periods = optional(number, 5)
      pending_duration   = optional(string)

      # OCI alarm severity enum: CRITICAL | ERROR | WARNING | INFO. Derived from
      # the severity KEY (sev1 -> CRITICAL, sev2 -> ERROR, sev3 -> WARNING,
      # sev4 -> INFO) unless set. AWS has no alarm-severity field at all - the
      # severity lives only in the alarm name and the SNS topic it routes to.
      oci_severity = optional(string)

      # AWS's actions_enabled.
      is_enabled = optional(bool, true)

      # Override the per-severity destination lookup for this one alarm.
      destinations = optional(list(string))

      # Renotify while still firing. No AWS counterpart (CloudWatch notifies on
      # state transition only). null = notify once per transition.
      repeat_notification_duration = optional(string)
    }))
  }))

  default = {}

  validation {
    condition     = alltrue([for k, v in var.classified_metric_alarms : contains(keys(v.severities), "sev1")])
    error_message = "Every classified_metric_alarm must define at least sev1 (critical severity)."
  }

  validation {
    condition = alltrue([
      for k, v in var.classified_metric_alarms : alltrue([
        for sk, sv in v.severities :
        sv.oci_severity == null || contains(["CRITICAL", "ERROR", "WARNING", "INFO"], sv.oci_severity)
      ])
    ])
    error_message = "oci_severity must be one of CRITICAL, ERROR, WARNING, INFO."
  }
}

# =============================================================================
# Classified anomaly alarms (features 5 & 6) - PLACEHOLDER, INTENTIONALLY UNUSABLE
# =============================================================================
# This variable accepts nothing. It exists so that anyone porting the AWS
# `classified_anomaly_alarms` input hits a loud, explanatory failure instead of
# quietly getting a static-threshold alarm that looks like the anomaly alarm it
# replaced. See main.tf for the full gap write-up.
variable "classified_anomaly_alarms" {
  description = "NOT IMPLEMENTABLE on OCI - features 5 & 6 are NONE. MQL has no anomaly-band, standard-deviation or moving-baseline function. Populating this variable fails validation on purpose; pick one of the two fallback paths in main.tf explicitly instead."
  type        = any
  default     = {}

  validation {
    condition     = length(keys(try(tomap(var.classified_anomaly_alarms), {}))) == 0
    error_message = "classified_anomaly_alarms cannot be implemented on OCI. MQL's statistical function set (mean, sum, count, min, max, percentile, rate, first, last, increment, absent) contains no anomaly-band equivalent of CloudWatch's ANOMALY_DETECTION_BAND, and no dedicated anomaly-alarm resource exists. The three real prod/us-east-1 anomaly alarms (RDS connection count, RDS write IOPS, OpenSearch JVM memory pressure) need an explicit decision between (a) a hand-tuned static threshold via classified_metric_alarms, accepting the loss of automatic baseline adaptation, or (b) an external job that computes a rolling mean/stdev band and publishes deviation as a custom metric an ordinary alarm watches. Oracle gate item, check sheet section 8 item 2 - NOT YET CONSULTED."
  }
}

# =============================================================================
# Logging (features 8, 9, 10)
# =============================================================================

variable "log_groups" {
  description = <<-EOT
    Map of log-group key to configuration. Note the retention split: AWS puts
    retention_in_days on the LOG GROUP; OCI's log group carries no retention or
    encryption argument at all - both live one level down on oci_logging_log.
    So `retention_duration` here is a default inherited by this group's logs, not
    a property of the group itself.
  EOT

  type = map(object({
    display_name = optional(string)
    description  = optional(string)

    # Days. OCI accepts 30-day increments up to 180. AWS's log groups all use 30
    # in this fleet, comfortably inside that ceiling (check sheet open question 4).
    default_retention_duration = optional(number, 30)

    freeform_tags = optional(map(string), {})
    defined_tags  = optional(map(string), {})
  }))

  default = {}
}

variable "logs" {
  description = <<-EOT
    Map of log key to configuration. One oci_logging_log each. This single
    variable covers BOTH of the AWS module's log-level features, because OCI
    models them as one resource with two `log_type` values:

      log_type = "CUSTOM"   feature 9's counterpart to aws_cloudwatch_log_stream.
                            PARTIAL: a heavy, individually-named, Terraform-managed
                            resource, not the cheap dynamically-created stream
                            CloudWatch offers. Fine for the static, pre-declared
                            use this module actually makes of streams; wrong for a
                            stream-per-pod-restart pattern.

      log_type = "SERVICE"  feature 10's SUBSTITUTE for
                            aws_cloudwatch_log_resource_policy. "Let service X
                            write into my log group" is declared per-source as its
                            own object rather than as a permission document on the
                            group. Requires the `source` block.
  EOT

  type = map(object({
    log_group_key = string
    display_name  = optional(string)
    log_type      = optional(string, "CUSTOM")
    is_enabled    = optional(bool, true)

    # Days; falls back to the log group's default_retention_duration.
    retention_duration = optional(number)

    # Required when log_type = "SERVICE". `resource` is the OCID of the emitting
    # resource, `service` and `category` come from Oracle's per-service logging
    # reference.
    source = optional(object({
      service     = string
      resource    = string
      category    = string
      source_type = optional(string, "OCISERVICE")
      parameters  = optional(map(string))
    }))

    freeform_tags = optional(map(string), {})
    defined_tags  = optional(map(string), {})
  }))

  default = {}

  validation {
    condition = alltrue([
      for k, v in var.logs : contains(["CUSTOM", "SERVICE"], v.log_type)
    ])
    error_message = "log_type must be CUSTOM or SERVICE."
  }

  validation {
    condition = alltrue([
      for k, v in var.logs : v.log_type != "SERVICE" || v.source != null
    ])
    error_message = "A log with log_type = \"SERVICE\" must set `source` - that block IS the substitute for AWS's log resource policy (check sheet feature 10)."
  }

  validation {
    condition = alltrue([
      for k, v in var.logs :
      v.retention_duration == null || (v.retention_duration % 30 == 0 && v.retention_duration >= 30 && v.retention_duration <= 180)
    ])
    error_message = "retention_duration must be a multiple of 30 between 30 and 180 days - OCI Logging's documented ceiling. AWS's arbitrary retention_in_days values do not all port."
  }
}

# =============================================================================
# Alarm defaults
# =============================================================================

variable "alarm_resolution" {
  description = "MQL evaluation resolution. Pinned rather than left to the provider default - see main.tf."
  type        = string
  default     = "1m"
}

variable "alarm_message_format" {
  description = "Notification body format: RAW | PRETTY_JSON | ONS_OPTIMIZED. No AWS counterpart."
  type        = string
  default     = "PRETTY_JSON"

  validation {
    condition     = contains(["RAW", "PRETTY_JSON", "ONS_OPTIMIZED"], var.alarm_message_format)
    error_message = "alarm_message_format must be RAW, PRETTY_JSON or ONS_OPTIMIZED."
  }
}

# =============================================================================
# Tagging
# =============================================================================

variable "freeform_tags" {
  description = "Freeform tags merged onto every alarm, log group and log (AWS `tags` analogue)"
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags (namespace.key = value). Requires the tag namespace to already exist in the tenancy."
  type        = map(string)
  default     = {}
}
