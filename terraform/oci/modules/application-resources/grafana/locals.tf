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

  # ---------------------------------------------------------------------------
  # THE GRANT LIST - check sheet section 10. Three statements.
  #
  # Each is conditioned on its own boolean so an environment that does not want
  # the OCI-datasource identity exception (see
  # `datasource_api_key_vault_secret_id`) can omit the grants entirely rather
  # than carrying permissions nothing exercises.
  #
  # READ THE VERBS. `read`, not `use`, on all three:
  #   read metrics      -> METRIC_INSPECT + METRIC_READ  (query for a dashboard)
  #   use  metrics      -> METRIC_WRITE                  (PUBLISH - otel-collector's)
  #   read log-content  -> LOG_CONTENT_READ, ListSearchLogs
  #   use  log-content  -> LOG_CONTENT_PUSH              (a shipper's)
  #   read log-groups   -> LOG_GROUP_READ                (the picker's enumeration)
  #
  # identity-model.md section 3.5 documents only the WRITE verbs, because
  # publishing was the only direction its covered modules needed. The read verbs
  # were verified while porting this module and are recorded in that document's
  # own header correction. A plan showing `use metrics` here is wrong.
  # ---------------------------------------------------------------------------
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
        # which log groups exist are separate permissions, and the Logs plugin's
        # compartment/log-group picker needs the second.
        verb          = "read"
        resource_type = "log-groups"
        location      = var.compartment_id
        condition     = null
      },
    ] : [],
  )

  # ---------------------------------------------------------------------------
  # THE STATEMENT RENDERER.
  #
  # THIS MODULE CREATES NO `oci_identity_policy`, and that is structural.
  # `oci_identity_policy.name` is tenancy-unique AND non-updatable; one object
  # per app per live root is 132 objects against a hard limit of 100
  # (identity-model.md section 3.7). ONE shared policy object per environment,
  # owned by `oke-workload-identity`, receives statements from every app module.
  #
  # The four `where all {}` conditions ARE the security boundary
  # (identity-model.md section 3.2), and the failure is asymmetric: on AWS a
  # malformed trust policy fails CLOSED, on OCI a statement missing
  # `request.principal.cluster_id` grants every cluster in the tenancy and the
  # API accepts it. All four are hard-coded below, not caller-controllable, and
  # `oke-workload-identity` re-validates at plan time.
  #
  # Pre-normalised and sorted (oracle/terraform-provider-oci#371). Only
  # `in compartment id <ocid>`; compartment NAMES are lowercased server-side.
  # ---------------------------------------------------------------------------
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

  # ---------------------------------------------------------------------------
  # THE DATABASE ADDS ZERO STATEMENTS, and that is worth stating rather than
  # leaving as an absence a reviewer has to notice.
  #
  # OCI Database with PostgreSQL has NO IAM-principal-to-database-user
  # authentication path (database.md section 4.14, feature 22, verdict NONE).
  # Grafana authenticates to its own database with a username and password over
  # mandatory TLS, not with a workload-identity-issued token. So "grafana has a
  # database dependency" does not translate into extra policy statements the way
  # it would on a cloud with IAM database auth.
  #
  # NOT INCLUDED ABOVE, and contingent on open questions:
  #   * `inspect compartments` / `read compartments` for the plugins' compartment
  #     picker (check sheet section 9 Q3). If required it likely needs a
  #     TENANCY-ROOT-scoped grant, which is a structural exception - a policy in
  #     `dev` cannot see sibling compartments' names - not one more statement in
  #     the same object. Contribute it via `extra_statements` against the
  #     appropriate compartment if the picker turns out to need it.
  #   * `read secret-bundles` on the database's Vault secret (section 9 Q4).
  #     This module assumes the external-secrets-operator relay, so Grafana's
  #     own workload identity gets no Vault grant. If the chart turns out to
  #     read Vault directly, that is +1 statement.
  # ---------------------------------------------------------------------------

  datasource_uses_static_credential = var.datasource_api_key_vault_secret_id != null
}
