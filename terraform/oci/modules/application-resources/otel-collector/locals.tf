# Grant list and statement renderer (canonical copy, re-checked by the shared
# policy's plan-time preconditions). NOTE WHAT IS ABSENT: anything to do with
# traces. APM ingestion is header-authenticated with a data key, not IAM.

locals {
  name_prefix = "${var.project_name}-${var.environment}-otel"

  metrics_compartment = coalesce(var.metrics_compartment_id, var.compartment_id)
  logs_compartment    = coalesce(var.logs_compartment_id, var.compartment_id)

  common_freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "otel-collector"
      managed_by  = "terraform"
    },
    var.region != null ? { region = var.region } : {},
    var.freeform_tags
  )

  # `use metrics` -> METRIC_WRITE -> PostMetricData.
  # `target.metrics.namespace` is a documented condition variable; the module
  # defaults to using it rather than granting `use metrics` unconditioned,
  # because it is tighter scoping than the AWS side can express at all.
  metrics_grants = var.enable_metrics_grant ? [{
    verb           = "use"
    resource_type  = "metrics"
    compartment_id = local.metrics_compartment
    condition      = var.metrics_namespace == null ? null : "target.metrics.namespace='${var.metrics_namespace}'"
  }] : []

  # `use log-content` -> LOG_CONTENT_PUSH.
  logs_grants = var.enable_logs_grant ? [{
    verb           = "use"
    resource_type  = "log-content"
    compartment_id = local.logs_compartment
    condition      = null
  }] : []

  extra_grants = [
    for g in var.additional_grants : {
      verb           = g.verb
      resource_type  = g.resource_type
      compartment_id = coalesce(g.compartment_id, var.compartment_id)
      condition      = g.condition
    }
  ]

  all_grants = concat(local.metrics_grants, local.logs_grants, local.extra_grants)

  grant_tuples = flatten([
    for g in local.all_grants : [
      for cluster_id in var.cluster_ids : {
        cluster_id      = cluster_id
        namespace       = lower(trimspace(var.k8s_namespace))
        service_account = lower(trimspace(var.k8s_service_account_name))
        verb            = lower(trimspace(g.verb))
        resource_type   = lower(trimspace(g.resource_type))
        location        = g.compartment_id
        condition       = g.condition == null ? "" : ",${trimspace(g.condition)}"
      }
    ]
  ])

  rendered_statements = [
    for t in local.grant_tuples : join("", [
      "allow any-user to ${t.verb} ${t.resource_type} in compartment id ${t.location} where all {",
      "request.principal.type='workload',",
      "request.principal.namespace='${t.namespace}',",
      "request.principal.service_account='${t.service_account}',",
      "request.principal.cluster_id='${t.cluster_id}'",
      t.condition,
      "}",
    ])
  ]

  policy_statements = sort(distinct([
    for s in concat(local.rendered_statements, var.shared_statements, var.extra_statements) :
    replace(
      replace(
        replace(
          replace(trimspace(s), "/\\s+/", " "),
        "/\\s*(!?=)\\s*/", "$1"),
      "/,\\s+/", ","),
    "/\\{\\s+|\\s+\\}/", "")
  ]))

  workload_grants = [
    for g in local.all_grants : {
      namespace       = lower(trimspace(var.k8s_namespace))
      service_account = lower(trimspace(var.k8s_service_account_name))
      verb            = lower(trimspace(g.verb))
      resource_type   = lower(trimspace(g.resource_type))
      compartment_id  = g.compartment_id
      condition       = g.condition
    }
  ]

  authorized_workloads = [
    for cluster_id in var.cluster_ids : {
      cluster_id      = cluster_id
      namespace       = lower(trimspace(var.k8s_namespace))
      service_account = lower(trimspace(var.k8s_service_account_name))
    }
  ]

  effective_apm_domain_id = var.create_apm_domain ? one(oci_apm_apm_domain.this[*].id) : var.apm_domain_id
  effective_log_group_id  = var.create_log_group ? one(oci_logging_log_group.this[*].id) : var.log_group_id
}
