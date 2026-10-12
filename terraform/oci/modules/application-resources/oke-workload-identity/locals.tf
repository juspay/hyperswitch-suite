# The statement renderer: every OCI workload grant in the platform is rendered
# here. Drops a condition fails OPEN on OCI, so the principal conditions are
# hard-coded into the template below.

locals {
  grant_tuples = flatten([
    for g in var.workload_grants : [
      for cluster_id in var.cluster_ids : {
        cluster_id      = cluster_id
        namespace       = lower(trimspace(g.namespace))
        service_account = lower(trimspace(g.service_account))
        verb            = lower(trimspace(g.verb))
        resource_type   = lower(trimspace(g.resource_type))
        location        = coalesce(g.compartment_id, var.compartment_id)
        condition       = g.condition == null ? "" : ",${trimspace(g.condition)}"
      }
    ]
  ])

  rendered_statements = [
    for t in local.grant_tuples :
    join("", [
      "allow any-user to ${t.verb} ${t.resource_type} in compartment id ${t.location} where all {",
      "request.principal.type='workload',",
      "request.principal.namespace='${t.namespace}',",
      "request.principal.service_account='${t.service_account}',",
      "request.principal.cluster_id='${t.cluster_id}'",
      t.condition,
      "}",
    ])
  ]

  # Bootstrap: the policy object must exist from wave 1 to claim its tenancy-
  # unique, NON-UPDATABLE name. The inert statement vanishes once a real grant
  # lands.
  composed_statements = concat(local.rendered_statements, var.statements)
  is_bootstrap_only   = length(local.composed_statements) == 0

  bootstrap_statement = join("", [
    "allow any-user to inspect compartments in compartment id ${var.compartment_id} where all {",
    "request.principal.type='workload',",
    "request.principal.namespace='hyperswitch-workload-identity-bootstrap',",
    "request.principal.service_account='hyperswitch-workload-identity-bootstrap',",
    "request.principal.cluster_id='${var.cluster_ids[0]}'",
    "}",
  ])

  raw_statements = local.is_bootstrap_only ? [local.bootstrap_statement] : local.composed_statements

  # Normalisation: the OCI API rewrites statement text server-side, so anything
  # not already in normal form produces a permanent diff. sort+distinct for a
  # stable plan.
  all_statements = sort(distinct([
    for s in local.raw_statements :
    replace(
      replace(
        replace(
          replace(trimspace(s), "/\\s+/", " "),
        "/\\s*(!?=)\\s*/", "$1"),
      "/,\\s+/", ","),
    "/\\{\\s+|\\s+\\}/", "")
  ]))

  # Fail-open guards, evaluated as resource preconditions in main.tf.
  # A statement that says `any-user` without pinning the principal type is a
  # grant to every principal in the tenancy.
  statements_without_principal_type = [
    for s in local.all_statements : s
    if length(regexall("any-user", s)) > 0 && length(regexall("request\\.principal\\.type='workload'", s)) == 0
  ]

  # A workload statement missing any of the other three conditions widens to
  # every cluster in the tenancy, or every pod in the namespace.
  workload_statements = [
    for s in local.all_statements : s
    if length(regexall("request\\.principal\\.type='workload'", s)) > 0
  ]

  statements_missing_conditions = [
    for s in local.workload_statements : s
    if length(regexall("request\\.principal\\.namespace='[^']+'", s)) == 0
    || length(regexall("request\\.principal\\.service_account='[^']+'", s)) == 0
    || length(regexall("request\\.principal\\.cluster_id='[^']+'", s)) == 0
  ]

  # Every cluster named in a statement must be one this policy was told about,
  # otherwise `cluster_ids` stops being an accurate description of the blast
  # radius and the audit output below lies.
  statements_with_unknown_cluster = [
    for s in local.workload_statements : s
    if !alltrue([
      for m in regexall("request\\.principal\\.cluster_id='([^']+)'", s) : contains(var.cluster_ids, m[0])
    ])
  ]

  # `in compartment <name>` is lowercased server-side; `in compartment id
  # <ocid>` is not. Only the latter is diff-stable.
  statements_with_named_compartment = [
    for s in local.all_statements : s
    if length(regexall(" in compartment ", s)) > 0 && length(regexall(" in compartment id ", s)) == 0
  ]

  # Audit surface: the tuples this policy actually authorises, recovered from the
  # final statement text so the output cannot drift from what was sent.
  authorized_workloads = distinct([
    for s in local.workload_statements : {
      cluster_id      = try(regexall("request\\.principal\\.cluster_id='([^']+)'", s)[0][0], "UNPARSEABLE")
      namespace       = try(regexall("request\\.principal\\.namespace='([^']+)'", s)[0][0], "UNPARSEABLE")
      service_account = try(regexall("request\\.principal\\.service_account='([^']+)'", s)[0][0], "UNPARSEABLE")
    }
  ])
}
