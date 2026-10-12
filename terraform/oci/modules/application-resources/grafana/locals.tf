locals {
  name_prefix = "${var.environment}-${var.project_name}"

  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "grafana"
      managed_by  = "terraform"
    },
    var.freeform_tags
  )

  # THE GRANT LIST. Three statements.
  #
  # READ THE VERBS. `read`, not `use`, on all three:
  #   read metrics     -> METRIC_INSPECT + METRIC_READ (querying for a dashboard)
  #   use  metrics     -> METRIC_WRITE                  (PUBLISH - otel-collector's)
  #   read log-content -> LOG_CONTENT_READ, ListSearchLogs
  #   use  log-content -> LOG_CONTENT_PUSH              (a shipper's)
  #   read log-groups  -> LOG_GROUP_READ                 (the picker's enumeration)
  # Each is conditioned on its own boolean so an environment can omit the grants.
  grants = concat(
    var.metrics_read_enabled ? [{
      verb          = "read"
      resource_type = "metrics"
      location      = var.compartment_id
      condition     = null
    }] : [],

    var.logs_read_enabled ? [
      {
        verb          = "read"
        resource_type = "log-content"
        location      = var.compartment_id
        condition     = null
      },
      {
        # Not implied by `read log-content`: searching log content and listing
        # which log groups exist are separate permissions.
        verb          = "read"
        resource_type = "log-groups"
        location      = var.compartment_id
        condition     = null
      },
    ] : [],
  )

  # THIS MODULE CREATES NO `oci_identity_policy`, and that is structural: `name`
  # is tenancy-unique and non-updatable, and one object per app per root exceeds
  # the hard 100-per-tenancy limit. ONE shared policy object per environment
  # (owned by `oke-workload-identity`) receives statements from every app module.
  #
  # The four `where all {}` conditions ARE the security boundary and are
  # hard-coded below, not caller-controllable. On AWS a malformed trust policy
  # fails CLOSED; on OCI a statement missing request.principal.cluster_id grants
  # every cluster in the tenancy and the API accepts it silently.
  #
  # Pre-normalised and sorted: the API rewrites statement text server-side, so
  # anything not in normal form is a permanent diff. Only `in compartment id <ocid>`.
  statement_tuples = flatten([
    for g in local.grants : [
      for cluster_id in var.cluster_ids : join("", [
        "allow any-user to ${lower(trimspace(g.verb))} ${lower(trimspace(g.resource_type))} in compartment id ${g.location} where all {",
        "request.principal.type='workload',",
        "request.principal.namespace='${lower(trimspace(var.k8s_namespace))}',",
        "request.principal.service_account='${lower(trimspace(var.k8s_service_account_name))}',",
        "request.principal.cluster_id='${cluster_id}'",
        g.condition == null ? "" : ",${trimspace(g.condition)}",
        "}",
      ])
    ]
  ])

  policy_statements = sort(distinct([
    for s in concat(local.statement_tuples, var.shared_statements, var.extra_statements) :
    replace(
      replace(
        replace(
          replace(trimspace(s), "/\\s+/", " "),
        "/\\s*(!?=)\\s*/", "$1"),
      "/,\\s+/", ","),
    "/\\{\\s+|\\s+\\}/", "")
  ]))

  authorized_workloads = [
    for cluster_id in var.cluster_ids : {
      cluster_id      = cluster_id
      namespace       = lower(trimspace(var.k8s_namespace))
      service_account = lower(trimspace(var.k8s_service_account_name))
    }
  ]

  # THE DATABASE ADDS ZERO STATEMENTS. OCI Database with PostgreSQL has no
  # IAM-principal-to-database-user auth path; Grafana connects with a username
  # and password over mandatory TLS, so a database dependency does not translate
  # into extra policy statements. Absent here and not silently dropped: grant
  # statements for the plugins' compartment picker (`inspect compartments`) or a
  # direct-Vault read would be added via `extra_statements` if ever required.

  datasource_uses_static_credential = var.datasource_api_key_vault_secret_id != null
}
