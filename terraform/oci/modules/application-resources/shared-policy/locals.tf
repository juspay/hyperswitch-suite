# The renderer. This is a SEPARATE Terragrunt unit with its own state, so it
# renders text across the boundary rather than owning a policy object. A dropped
# condition here is caught by oke-workload-identity's plan-time preconditions
# (fails OPEN on OCI otherwise). Prefer `workload_grants` over `policy_statements`
# when wiring in - the canonical renderer cannot forget a condition.

locals {
  # One tuple per (grant x subject x cluster). Enumerated, not collapsed: no
  # verified wildcard on request.principal.*.
  grant_tuples = flatten([
    for key, g in var.grants : [
      for s in var.subjects : [
        for cluster_id in var.cluster_ids : {
          key             = key
          cluster_id      = cluster_id
          namespace       = lower(trimspace(s.namespace))
          service_account = lower(trimspace(s.service_account))
          verb            = lower(trimspace(g.verb))
          resource_type   = lower(trimspace(g.resource_type))
          location        = coalesce(g.compartment_id, var.compartment_id)
          condition       = g.condition == null ? "" : ",${trimspace(g.condition)}"
        }
      ]
    ]
  ])

  # `any-user` is the subject because a workload has no group to name. Oracle
  # recommends against bare `any-user` and is right to: it covers every user,
  # instance principal, resource principal and service principal in the tenancy.
  # `request.principal.type='workload'` is the ONLY thing that narrows it, which
  # is why it is hard-coded into the template rather than caller-supplied.
  raw_statements_by_key = {
    for key in keys(var.grants) : key => [
      for t in local.grant_tuples : join("", [
        "allow any-user to ${t.verb} ${t.resource_type} in compartment id ${t.location} where all {",
        "request.principal.type='workload',",
        "request.principal.namespace='${t.namespace}',",
        "request.principal.service_account='${t.service_account}',",
        "request.principal.cluster_id='${t.cluster_id}'",
        t.condition,
        "}",
      ]) if t.key == key
    ]
  }

  # Normalisation, four rules, identical to oke-workload-identity/locals.tf.
  # The OCI API rewrites statement text server-side (collapses whitespace,
  # strips spaces inside `where` clauses), so anything not already in normal
  # form produces a permanent un-suppressable diff
  # (oracle/terraform-provider-oci#371). A fifth rule - lowercase compartment
  # NAMES - is designed out rather than implemented: only `in compartment id
  # <ocid>` is ever emitted, and named compartments are rejected in
  # variables.tf. OCIDs are not rewritten.
  statements_by_grant = {
    for key, list in local.raw_statements_by_key : key => sort(distinct([
      for s in list :
      replace(
        replace(
          replace(
            replace(trimspace(s), "/\\s+/", " "),
          "/\\s*(!?=)\\s*/", "$1"),
        "/,\\s+/", ","),
      "/\\{\\s+|\\s+\\}/", "")
    ]))
  }

  # `sort` + `distinct` for a stable plan. Never let statement order fall out of
  # unordered iteration over a map: the resulting list churn is
  # indistinguishable from a real permission change in a plan diff.
  policy_statements = sort(distinct(flatten(values(local.statements_by_grant))))

  # The structured form of the same grants, for callers that would rather feed
  # `oke-workload-identity.workload_grants` (the safer channel) than
  # `.statements`.
  workload_grants = [
    for t in local.grant_tuples : {
      namespace       = t.namespace
      service_account = t.service_account
      verb            = t.verb
      resource_type   = t.resource_type
      compartment_id  = t.location
      condition       = var.grants[t.key].condition
    } if t.cluster_id == var.cluster_ids[0]
  ]

  authorized_workloads = distinct([
    for t in local.grant_tuples : {
      cluster_id      = t.cluster_id
      namespace       = t.namespace
      service_account = t.service_account
    }
  ])
}
