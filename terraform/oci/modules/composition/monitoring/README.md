# monitoring

OCI Monitoring alarms and OCI Logging log groups/logs. The alerting and
log-retention backbone.

Counterpart of `terraform/aws/modules/composition/cloudwatch` and
`terraform/gcp/modules/composition/cloud-monitoring`. Parity analysis:
`hyperswitch-infra/docs/multi-cloud-parity/oci/modules/cloudwatch.md`
(7 FULL / 2 PARTIAL / 2 SUBSTITUTE / 2 NONE).

## The MQL builder

AWS gives an alarm five typed fields plus a comparison operator. OCI gives it one
string:

```
CpuUtilization[5m]{resourceId = "ocid1.cluster..."}.groupBy(resourceId).mean() >= 80
```

`locals.tf` renders that from the **same typed variable surface the AWS module
already has**, on purpose: whoever writes 95 `classified_metric_alarms` entries
per environment understands those fields, and hand-written MQL would move
mistyped metric names and statistics from a Terraform type error to an API-time
failure.

Translation tables live in `locals.tf`: AWS statistic names → MQL functions, AWS
comparison-operator names → MQL operators, `period` seconds → `[interval]`,
severity key → OCI's required `severity` enum, `evaluation_periods × period` →
`pending_duration`. MQL names pass through untranslated, so raw MQL still works
field-by-field, and `query_override` takes a whole query verbatim.

**`terraform validate` cannot check MQL grammar.** The `classified_alarm_queries`
output exists so a human can read a sample - that is validation-ladder rung 5 for
this module (check sheet open question 5).

## Two things OCI will not let you do that AWS will

- **An alarm must have a destination.** `destinations` is required and non-empty.
  An AWS alarm with empty `alarm_actions` is legal and quietly notifies nobody; a
  precondition here turns that into a plan-time failure.
- **`pending_duration` maxes out at `PT1H`.** `evaluation_periods × period` above
  60 minutes is a precondition failure rather than a silent clamp, because
  shortening an evaluation window changes what an alarm means.

## What this module does not have, and why

| AWS feature | Status | Note |
|---|---|---|
| Composite / metric-math alarms | **SUBSTITUTE** | MQL arithmetic works within one metric's stream; joins combine booleans, not numbers. The real `waf-cloudfront-heartbeat` sev1 alarm cannot be ported without changing its meaning. Substitute is a synthetic custom metric plus an ordinary alarm. |
| Anomaly-detection alarms (both variants) | **NONE** | MQL has no anomaly band, stdev envelope or moving baseline. Three real prod alarms affected. The `classified_anomaly_alarms` variable fails validation on purpose. |
| `ok_actions` / `insufficient_data_actions` / `skip_ok_action` | absent | One `destinations` list, used for firing **and** reset. Expect roughly double the notification volume unless the destination filters resets. |
| `treat_missing_data` | absent | MQL's `absent()` is a separate alarm, not a modifier. |
| `datapoints_to_alarm` | absent | No M-of-N; `pending_duration` is one continuous window - stricter, quieter on a flapping metric. |
| Log resource policy | SUBSTITUTE | `oci_logging_log` with `log_type = "SERVICE"` and a `source` block, one per emitting service, instead of one document on the group. |
| Log streams | PARTIAL | `oci_logging_log` with `log_type = "CUSTOM"` - a heavier primitive. Fine for static declaration, wrong for stream-per-pod-restart. |
| Dashboards | PARTIAL, not carried | Bulk JSON import, not a per-dashboard resource. Unused on AWS; Grafana covers this. |
| Plain `metric_alarms` | FULL, not carried | Unused on AWS. A single-severity `classified_metric_alarms` entry is the same thing. |

Retention moves: AWS puts `retention_in_days` on the log **group**; OCI puts it
on the **log**. `log_groups[].default_retention_duration` preserves the AWS
mental model by having logs inherit it. The OCI ceiling is 180 days in 30-day
increments, so not every AWS retention value ports.

## Oracle gate

Not yet consulted. Check sheet section 8: composite alarms (present the actual
WAF heartbeat, not an abstraction), anomaly alarms (the item most likely to need
a real decision), and the log resource policy substitute.
