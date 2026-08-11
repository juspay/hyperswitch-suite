# ============================================================================
# Cloud Monitoring (GCP equivalent of composition/cloudwatch)
# ============================================================================
# Notification channels, alert policies, log-based metrics, and dashboards -
# mirroring the AWS module's SNS-action metric/composite/anomaly alarms +
# log groups + dashboard shape. Cloud Monitoring's `combiner` field on an
# alert policy plays the role of a CloudWatch composite alarm: a policy
# whose conditions reference other policies' underlying metrics.
#
# Log sinks (the equivalent of the AWS module's CloudWatch Logs export
# destinations) are built on terraform-google-modules/log-export, one call
# per destination.
#
# Usage:
#   module "cloud_monitoring" {
#     source = "../../modules/composition/cloud-monitoring"
#
#     project_id  = "hyperswitch-dev"
#     environment = "dev"
#
#     notification_channels = {
#       platform-pagerduty = { type = "pubsub", labels = { topic = module.pubsub.topic_id } }
#     }
#
#     alert_policies = {
#       high-cpu = {
#         display_name = "High CPU"
#         combiner     = "OR"
#         conditions = [{
#           display_name = "CPU > 80%"
#           filter       = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
#           comparison   = "COMPARISON_GT"
#           threshold_value = 0.8
#           duration     = "300s"
#         }]
#         notification_channel_keys = ["platform-pagerduty"]
#       }
#     }
#   }
# ============================================================================

resource "google_monitoring_notification_channel" "this" {
  for_each = var.notification_channels

  project      = var.project_id
  display_name = "${local.name_prefix}-${each.key}"
  type         = each.value.type
  labels       = each.value.labels
  description  = try(each.value.description, null)
  enabled      = try(each.value.enabled, true)
}

resource "google_monitoring_alert_policy" "this" {
  for_each = var.alert_policies

  project      = var.project_id
  display_name = "${local.name_prefix}-${each.key}"
  combiner     = each.value.combiner

  dynamic "conditions" {
    for_each = each.value.conditions
    content {
      display_name = conditions.value.display_name

      condition_threshold {
        filter          = conditions.value.filter
        comparison      = conditions.value.comparison
        threshold_value = conditions.value.threshold_value
        duration        = conditions.value.duration
        aggregations {
          alignment_period   = try(conditions.value.alignment_period, "60s")
          per_series_aligner = try(conditions.value.per_series_aligner, "ALIGN_MEAN")
        }
      }
    }
  }

  notification_channels = [
    for key in each.value.notification_channel_keys :
    google_monitoring_notification_channel.this[key].id
  ]

  documentation {
    content   = try(each.value.documentation, "Managed by Terraform (composition/cloud-monitoring)")
    mime_type = "text/markdown"
  }

  user_labels = try(each.value.labels, {})
}

resource "google_logging_metric" "this" {
  for_each = var.log_metrics

  project     = var.project_id
  name        = "${local.name_prefix}-${each.key}"
  filter      = each.value.filter
  description = try(each.value.description, null)

  metric_descriptor {
    metric_kind = try(each.value.metric_kind, "DELTA")
    value_type  = try(each.value.value_type, "INT64")
    unit        = try(each.value.unit, "1")
  }
}

resource "google_monitoring_dashboard" "this" {
  for_each = var.dashboards

  project        = var.project_id
  dashboard_json = jsonencode(each.value)
}

# ==============================================================================
# Log sinks
# ==============================================================================
module "log_sinks" {
  source  = "terraform-google-modules/log-export/google"
  version = "11.1.0"

  for_each = var.log_sinks

  destination_uri        = each.value.destination_uri
  filter                 = each.value.filter
  log_sink_name          = "${local.name_prefix}-${each.key}"
  parent_resource_type   = "project"
  parent_resource_id     = var.project_id
  unique_writer_identity = true
}
