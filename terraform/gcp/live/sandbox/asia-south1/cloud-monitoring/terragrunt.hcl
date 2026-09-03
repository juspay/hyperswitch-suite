# Baseline notification channel + a couple of representative alert
# policies. Extend `alert_policies` as real SLOs are defined.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/cloud-monitoring?ref=gcp-cloud-monitoring-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  notification_channels = {
    platform-email = {
      type   = "email"
      labels = { email_address = values.alert_notification_email }
    }
  }

  alert_policies = {
    gke-node-cpu-high = {
      combiner = "OR"
      conditions = [
        {
          display_name    = "GKE node CPU > 85%"
          filter          = "resource.type=\"k8s_node\" AND metric.type=\"kubernetes.io/node/cpu/allocatable_utilization\""
          comparison      = "COMPARISON_GT"
          threshold_value = 0.85
          duration        = "300s"
        },
      ]
      notification_channel_keys = ["platform-email"]
    }
  }

  log_metrics = {}
  dashboards  = {}
  log_sinks   = {}
}
