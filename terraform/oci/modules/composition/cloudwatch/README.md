# cloudwatch (OCI) → OCI Monitoring + Logging

OCI equivalent of `terraform/aws/modules/composition/cloudwatch`. Uses `oci_monitoring_alarm` (alarms) and
`oci_logging_log_group`/`oci_logging_log` (log groups/streams). No verified registry module exists for either
service - raw `oci` provider resources.

## Mapping notes

- AWS alarm query pieces (`namespace`, `metric_name`, `statistic`, `period`, `comparison_operator`, `threshold`)
  collapse into a single OCI **MQL query string** (`query`), e.g.
  `"CpuUtilization[1m]{resourceId = \"<ocid>\"}.mean() > 80"`. There is no per-field mapping — build the MQL
  string per alarm.
- AWS `alarm_actions`/`ok_actions` (SNS topic ARNs) → OCI `destinations` (ONS topic OCIDs, from the sibling
  `../sns` module) — OCI alarms don't distinguish "alarm" vs. "ok" destinations; all destinations receive both
  firing and clearing notifications, differentiated by the notification payload's `status` field.
- Composite alarms / metric-math alarms (`aws_cloudwatch_metric_alarm` with `metric_query` blocks) map to MQL
  expressions combining multiple queries — expressible in a single `query` string, not modeled as a separate
  resource type.
- Anomaly detection alarms have no OCI Monitoring equivalent — omitted.
- Dashboards (`aws_cloudwatch_dashboard`) have no equivalent in OCI Monitoring; use Grafana (already deployed via
  the `grafana` application-resources module) for dashboards instead.
