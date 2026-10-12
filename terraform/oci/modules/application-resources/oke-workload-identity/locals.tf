# -----------------------------------------------------------------------------
# The statement renderer.
#
# This file is the security boundary of the whole identity port. Every OCI
# workload grant in the platform is rendered here and nowhere else, for the
# reason set out in identity-model.md section 2.3: a copy-pasted IRSA block that
# drops a condition fails closed on AWS, and a copy-pasted OCI statement that
# drops a condition fails OPEN. CI should reject a literal `request.principal`
# string appearing in any module other than this one.
# -----------------------------------------------------------------------------

locals {
  # ---------------------------------------------------------------------------
  # Step 1 - render `workload_grants` x `cluster_ids`.
  #
  # One statement per (cluster, namespace, service_account, grant) tuple. There
  # is no confirmed wildcard on `request.principal.*`, so tuples are enumerated
  # rather than collapsed - see eks-iam.md section 4.2.
  #
  # `any-user` is the subject because a workload has no group to name. Oracle
  # recommends against bare `any-user`, and is right to: it covers every user,
  # instance principal, resource principal and service principal in the tenancy.
  # `request.principal.type='workload'` is the ONLY thing that narrows it. That
  # condition is not optional and is not caller-controlled - it is hard-coded
  # into the template below.
  # ---------------------------------------------------------------------------
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

  # ---------------------------------------------------------------------------
  # Step 2 - bootstrap.
  #
  # `oci_identity_policy.statements` is required and an empty policy is not a
  # thing the API accepts, but this policy object must exist from wave 1 -
  # before any application module has been ported - so that its tenancy-unique,
  # NON-UPDATABLE name is claimed once and never has to change.
  #
  # This statement is inert: it authorises a service account that does not and
  # will not exist, to `inspect compartments`, which returns metadata only. It
  # is emitted only while the composed statement list is empty and vanishes on
  # the plan that adds the first real grant - no flag to remember to flip.
  # ---------------------------------------------------------------------------
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

  # ---------------------------------------------------------------------------
  # Step 3 - normalisation.
  #
  # The OCI API rewrites policy statement text server-side - it collapses
  # whitespace between keywords and strips spaces inside `where` clauses - which
  # produces a permanent, un-suppressable Terraform diff if what we send is not
  # already in normal form (oracle/terraform-provider-oci#371).
  #
  # Four rules, applied to everything this module emits, so that contributed
  # statements written in the readable spaced-out form still land diff-stable:
  #   1. runs of whitespace collapse to a single space;
  #   2. spaces around `=` and `!=` are removed;
  #   3. a space after a comma is removed (condition lists, subject lists and
  #      resource-type lists all accept the compact form);
  #   4. spaces just inside `{` and `}` are removed.
  #
  # A fifth rule - lowercase compartment NAMES - is designed out rather than
  # implemented: this module only ever emits `in compartment id <ocid>`, never
  # `in compartment <name>`, and rejects contributed statements that use a name
  # (see `statements_with_named_compartment` below). OCIDs are not rewritten.
  #
  # `sort` + `distinct` give a stable plan. Never let statement order fall out
  # of unordered iteration over a map or a set: the resulting list churn is
  # indistinguishable from a real permission change in a plan diff.
  # ---------------------------------------------------------------------------
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

  # ---------------------------------------------------------------------------
  # Step 4 - fail-open guards. Evaluated as resource preconditions in main.tf so
  # they abort the plan rather than the apply.
  # ---------------------------------------------------------------------------

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

  # ---------------------------------------------------------------------------
  # Step 5 - audit surface: the (cluster, namespace, service_account) tuples
  # this policy actually authorises, recovered from the final statement text
  # rather than from the inputs - so contributed statements are covered too, and
  # so the output cannot drift from what was sent to the API.
  # ---------------------------------------------------------------------------
  authorized_workloads = distinct([
    for s in local.workload_statements : {
      cluster_id      = try(regexall("request\\.principal\\.cluster_id='([^']+)'", s)[0][0], "UNPARSEABLE")
      namespace       = try(regexall("request\\.principal\\.namespace='([^']+)'", s)[0][0], "UNPARSEABLE")
      service_account = try(regexall("request\\.principal\\.service_account='([^']+)'", s)[0][0], "UNPARSEABLE")
    }
  ])
}
