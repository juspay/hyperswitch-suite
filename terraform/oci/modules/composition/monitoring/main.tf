# =============================================================================
# Monitoring + Logging - the OCI counterpart of
# aws/modules/composition/cloudwatch and gcp/modules/composition/cloud-monitoring.
#
# Check sheet: hyperswitch-infra/docs/multi-cloud-parity/oci/modules/cloudwatch.md
# Parity headline recorded there: 7 FULL / 2 PARTIAL / 2 SUBSTITUTE / 2 NONE.
#
# The AWS module is 635 lines and 14 variables, but its real usage is narrow:
# across all four live roots, only `classified_metric_alarms` and
# `classified_anomaly_alarms` carry real content. `metric_alarms`,
# `metric_anomaly_alarms` and `dashboards` are unused everywhere;
# `composite_alarms` is used exactly once. This module ports what is used, and
# records what is not - see the closing section of this file.
# =============================================================================

# -----------------------------------------------------------------------------
# Classified multi-severity metric alarms (feature 4, FULL)
# -----------------------------------------------------------------------------
# One resource per (alarm, severity) pair, from the same flattening local the AWS
# module already uses. In prod/us-east-1 that is 95 definitions -> 203 resources.
# The dev cut should start with a deliberately small subset; a first plan with
# 203 adds is not reviewable.
resource "oci_monitoring_alarm" "classified" {
  for_each = local.classified_alarms_flat

  compartment_id = var.compartment_id
  display_name   = each.value.display_name

  # Two compartments where AWS has one implicit scope: where the alarm object
  # lives, and where the metrics it evaluates are emitted. Usually the same.
  metric_compartment_id            = local.metric_compartment_id
  metric_compartment_id_in_subtree = var.metric_compartment_id_in_subtree

  namespace      = each.value.namespace
  resource_group = each.value.resource_group

  # The rendered MQL string. See locals.tf for the builder and its one known
  # limit: terraform validate cannot check MQL grammar.
  query = each.value.query

  # Pinned rather than left to the provider default. "1m" is the only resolution
  # this fleet's alarm periods need, and a provider-default change must not
  # silently move every alarm's evaluation cadence.
  resolution = var.alarm_resolution

  # AWS's evaluation_periods x period, expressed as one continuous window.
  pending_duration = each.value.pending_duration

  # Required enum with no AWS counterpart - see locals.severity_enum.
  severity = each.value.oci_severity

  body           = each.value.body
  message_format = var.alarm_message_format

  is_enabled = each.value.is_enabled

  # Feature 7, FULL. Per-severity routing, exactly reproducing AWS's
  # `alarm_actions = [lookup(var.sns_topic_arns, severity, "")]`. Oracle allows
  # one destination per destination service, which is why the per-severity split
  # above is not optional: it IS the routing mechanism.
  destinations = each.value.destinations

  # No AWS counterpart (CloudWatch notifies on state transition only).
  repeat_notification_duration = each.value.repeat_notification_duration

  freeform_tags = merge(local.freeform_tags, each.value.additional_tags)
  defined_tags  = var.defined_tags

  # ---------------------------------------------------------------------------
  # FIVE AWS ALARM FIELDS WITH NO COUNTERPART, dropped rather than faked:
  #
  #   ok_actions / insufficient_data_actions
  #     An OCI alarm has ONE destinations list, used for both the firing and the
  #     reset notification. There is no separate OK route and no
  #     "insufficient data" state to act on at all. Consequence: where an AWS
  #     alarm can notify a pager on breach and stay silent on recovery,
  #     every OCI alarm here notifies its destination on recovery too.
  #
  #   skip_ok_action
  #     Follows from the above - there is nothing to skip. Every AWS
  #     classified alarm in this fleet sets skip_ok_action = true by default, so
  #     this is a real behaviour change on port: expect roughly double the
  #     notification volume unless the destination filters resets.
  #
  #   treat_missing_data
  #     No missing-data policy exists. MQL has an absent() function, but it is a
  #     SEPARATE alarm ("this metric stopped reporting"), not a modifier on this
  #     one. An AWS alarm with treat_missing_data = "notBreaching" ports as an
  #     alarm with no missing-data handling; if the missing case matters, it
  #     needs its own absent()-based alarm via query_override.
  #
  #   datapoints_to_alarm
  #     No M-of-N evaluation. pending_duration is a single continuous window, so
  #     "3 of the last 5 datapoints" becomes "continuously breaching for N
  #     minutes" - stricter, and therefore quieter, for a flapping metric.
  #
  #   threshold_metric_id
  #     Only meaningful with an anomaly band. See features 5 & 6 below.
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # A note on `overrides`, which this module does NOT use.
  #
  # oci_monitoring_alarm has an `overrides` block that can vary query, severity,
  # pending_duration and body per rule within ONE alarm resource - which looks
  # like a way to collapse the per-severity fan-out. It is not: `destinations` is
  # an alarm-level argument, not an override-level one, so a single alarm cannot
  # route sev1 to the pager topic and sev2 to the mailing list. Per-severity
  # resources stay.
  # ---------------------------------------------------------------------------
}

# -----------------------------------------------------------------------------
# FEATURES 5 & 6 - ANOMALY-DETECTION ALARMS: NONE. NO RESOURCE HERE.
# -----------------------------------------------------------------------------
# There is no `oci_monitoring_alarm.classified_anomaly` block in this file, and
# there is deliberately no count = 0 stub either - a stub implies the pattern
# works and only needs switching on.
#
# Confirmed against docs.oracle.com/iaas/Content/Monitoring/Reference/mql.htm:
# MQL's entire statistical function set is mean()/avg(), sum(), count(), min(),
# max(), percentile(), rate(), first(), last(), increment() and absent(). There
# is no anomaly band, no standard-deviation envelope, no moving baseline.
# CloudWatch's ANOMALY_DETECTION_BAND(m1, stdev) has nothing to map to, and no
# dedicated anomaly-alarm resource exists in the provider.
#
# This is not a dormant capability. prod/us-east-1 runs three real classified
# anomaly alarms - RDS connection count, RDS write IOPS, OpenSearch JVM memory
# pressure - each with a sev1 band at 4 standard deviations and a sev2 at 2.
# Those three metrics were chosen for anomaly detection precisely BECAUSE a fixed
# number is a poor fit: connection counts and IOPS both have real daily and
# weekly cycles. They are the population where losing this hurts most.
#
# Two non-equivalent fallback paths, neither picked here:
#   (a) a hand-tuned static threshold via classified_metric_alarms - loses the
#       "adapts automatically" property that was the entire reason these three
#       alarms are anomaly alarms;
#   (b) an external job computing a rolling mean/stdev band and publishing
#       "standard deviations from baseline" as a custom metric, which an ordinary
#       MQL threshold alarm then watches - a reimplementation of CloudWatch's
#       anomaly math outside the platform, plus a new job to own and monitor for
#       its own failure.
#
# The `classified_anomaly_alarms` variable exists and fails validation if
# populated, so the choice has to be made consciously.
#
# Oracle gate item, check sheet section 8 item 2 - NOT YET CONSULTED. Re-check
# check sheet open question 1 (has a newer provider or MQL grammar added an
# anomaly function?) immediately before the gate convenes; a yes would change
# the whole conversation.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# FEATURE 3 - COMPOSITE / METRIC-MATH ALARMS: SUBSTITUTE. NO RESOURCE HERE.
# -----------------------------------------------------------------------------
# No `composite_alarms` input and no resource, because MQL cannot express one.
#
# Verified against the MQL reference: arithmetic operators (+ - * / %) work
# WITHIN a single metric's own stream (Oracle's own example: 100 -
# CpuUtilization[1m].mean()). Combining DIFFERENT metrics is only possible with
# join queries using && / ||, which combine already-threshold-evaluated BOOLEAN
# predicates, not raw numeric values. There is no construct that sums two metric
# streams into one number and compares that number once.
#
# The concrete case, and the reason this must not be ported mechanically:
# prod/us-east-1's `waf-cloudfront-heartbeat`, a sev1 production alarm that sums
# AllowedRequests + BlockedRequests + CountedRequests via
# FILL(allowed,0)+FILL(blocked,0)+FILL(counted,0) and asks whether the WAF
# evaluated ANY traffic in two 5-minute windows.
#
# The closest MQL rewrite -
#   AllowedRequests[1m].sum() < a && BlockedRequests[1m].sum() < b && CountedRequests[1m].sum() < c
# - is a DIFFERENT ALARM. It fires only when all three are individually low,
# where the original fires when the TOTAL is low. A traffic mix shifting entirely
# from allowed to blocked evaluates differently under the two. Porting it under
# the same name is the realistic failure mode: not "the alarm disappeared" but
# "the alarm quietly means something else".
#
# The real substitute is architectural: publish a synthetic custom metric that
# already contains the derived value (or, for this specific alarm, check whether
# the edge service can emit a single "requests evaluated" counter and sidestep
# the sum entirely), then watch it with an ordinary single-metric alarm - which
# is FULL on OCI. That is a metric-publishing job to build, own, and monitor for
# its own failure; CloudWatch's inline metric math needed none.
#
# `query_override` on classified_metric_alarms is the escape hatch for anything
# MQL CAN express that the typed builder cannot. It is not a composite-alarm
# mechanism and must not be used to smuggle an AND-joined rewrite of the WAF
# heartbeat in under the original's name.
#
# Oracle gate item, check sheet section 8 item 1 - NOT YET CONSULTED. Present the
# actual WAF alarm, not an abstract description.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Log groups (feature 8, FULL)
# -----------------------------------------------------------------------------
# Note what is NOT on this resource, and is on AWS's: retention_in_days and
# kms_key_id. Both live one level down, on oci_logging_log. The `log_groups`
# variable still accepts a default retention, which the logs inherit, so the AWS
# mental model produces the right answer - but the API shape is different and
# a group with no logs under it retains nothing because it stores nothing.
resource "oci_logging_log_group" "this" {
  for_each = local.log_groups

  compartment_id = var.compartment_id
  display_name   = each.value.display_name
  description    = each.value.description

  freeform_tags = each.value.freeform_tags
  defined_tags  = each.value.defined_tags
}

# -----------------------------------------------------------------------------
# Logs - features 9 (PARTIAL) and 10 (SUBSTITUTE), one resource, two log_types
# -----------------------------------------------------------------------------
# log_type = "CUSTOM" is feature 9's counterpart to aws_cloudwatch_log_stream.
#   PARTIAL, and the gap is about weight rather than capability: an AWS log
#   stream is a cheap, arbitrarily-named subdivision commonly created on the fly
#   by the logging agent, one per container or pod restart. An oci_logging_log is
#   a Terraform-managed resource with its own lifecycle, retention and
#   enable/disable flag. It fits the static, pre-declared usage this module
#   actually makes of streams (and `log_streams` is unpopulated in every AWS live
#   root reviewed, so zero blast radius today). It does NOT fit a
#   stream-per-instance pattern, and there is no lighter sibling resource to
#   reach for - route that through the logging agent's own multiplexing
#   (structured fields inside one log) instead.
#
# log_type = "SERVICE" is feature 10's SUBSTITUTE for
# aws_cloudwatch_log_resource_policy.
#   AWS attaches a JSON document to the log group granting OTHER SERVICES
#   permission to write into it. OCI inverts this: there is no policy document on
#   the group at all; each emitting source gets its own log object naming the
#   service, the source resource's OCID and the log category. "Grant service X
#   permission to log here" becomes "create a log bound to service X".
#   N small resources instead of 1 document covering many sources - fully
#   capable, differently shaped. This is the one gap in this module backed by a
#   directly-read resource schema rather than an inference.
#   Unused in every AWS live root reviewed.
#
#   Oracle gate item, check sheet section 8 item 3 - NOT YET CONSULTED.
resource "oci_logging_log" "this" {
  for_each = local.logs

  log_group_id = oci_logging_log_group.this[each.value.log_group_key].id
  display_name = each.value.display_name
  log_type     = each.value.log_type
  is_enabled   = each.value.is_enabled

  # Days. 30-day increments to a 180-day ceiling - narrower than AWS's arbitrary
  # retention_in_days. This fleet uses 30 everywhere, comfortably inside it.
  retention_duration = each.value.retention_duration

  dynamic "configuration" {
    for_each = each.value.source != null ? [each.value.source] : []

    content {
      compartment_id = var.compartment_id

      source {
        service     = configuration.value.service
        resource    = configuration.value.resource
        category    = configuration.value.category
        source_type = configuration.value.source_type
        parameters  = configuration.value.parameters
      }
    }
  }

  freeform_tags = each.value.freeform_tags
  defined_tags  = each.value.defined_tags
}

# -----------------------------------------------------------------------------
# FEATURE 11 - DASHBOARDS: PARTIAL, NOT CARRIED FORWARD.
# -----------------------------------------------------------------------------
# No `dashboards` input and no oci_management_dashboard_management_dashboards_import
# resource. Two reasons, both recorded rather than assumed:
#
#   1. Zero current usage. `dashboards` is unused in every AWS live root; this
#      platform's dashboards live in the separate `grafana` application-resources
#      module, whose model is cloud-agnostic and is very likely the better answer
#      regardless of cloud.
#   2. The OCI primitive is a poor fit for Terraform. It is a BULK IMPORT
#      operation over an exported JSON bundle, not a per-dashboard resource:
#      no dashboard_name argument, no 1:1 resource-to-dashboard mapping, and
#      destroying it does not necessarily delete what it imported. Its
#      Attributes Reference is empty, which hints its idempotency does not behave
#      the way Terraform users expect (check sheet open question 3).
#
# Adding it later is cheap. Adding it now would be adding an untested,
# poorly-shaped resource nobody uses.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# FEATURE 2 - PLAIN SINGLE-METRIC ALARMS: FULL, but not carried forward either.
# -----------------------------------------------------------------------------
# `metric_alarms` (AWS's non-classified variant) is unused in every live root
# reviewed. The capability is fully present on OCI - a single-severity entry in
# classified_metric_alarms is exactly that alarm - so this is an input-surface
# decision, not a parity gap. Trivial to add if a real consumer appears.
# -----------------------------------------------------------------------------
