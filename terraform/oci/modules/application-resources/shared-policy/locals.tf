# -----------------------------------------------------------------------------
# The renderer.
#
# DIVERGENCE, DELIBERATE, RECORDED HERE BECAUSE THIS IS WHERE IT LIVES.
# identity-model.md section 2.3 requires that policy statement text be rendered
# in EXACTLY ONE place - `oke-workload-identity/locals.tf` - and suggests CI
# reject a literal `request.principal` string anywhere else. The reason is
# sharp: on AWS a copy-pasted trust block that drops a condition fails CLOSED
# (the assume call is rejected); on OCI a copy-pasted statement that drops a
# condition fails OPEN, silently, with no error.
#
# This module renders statements anyway, because the shared policy object is a
# SEPARATE TERRAGRUNT UNIT with its own state: text is the only thing that can
# cross that boundary, and `oke-workload-identity`'s own header describes
# exactly this ("per-app statements get added here incrementally"). The
# mitigation is that the aggregation point re-validates: every string handed to
# `oke-workload-identity.statements` is checked at PLAN time by four
# preconditions in its main.tf - principal type present, all three other
# conditions present, cluster pinned to a known OCID, no named compartment. So
# a dropped condition here fails the plan there. The template below is a
# character-for-character copy of that module's, so the two cannot disagree
# about normal form.
#
# PREFER `workload_grants` OVER `policy_statements` when wiring this module's
# output into `oke-workload-identity`: the structured channel is rendered by
# the canonical renderer and cannot forget a condition at all.
# -----------------------------------------------------------------------------

locals {
  # One tuple per (grant x subject x cluster). Enumerated, not collapsed:
  # pattern values on `request.principal.*` are undocumented (identity-model.md
  # section 9 Q5), so there is no verified wildcard to collapse them with.
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
