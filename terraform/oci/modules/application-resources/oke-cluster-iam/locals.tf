locals {
  # Bootstrap: the policy must exist from the first cluster to claim its
  # tenancy-unique, NON-UPDATABLE name. The inert statement vanishes once a real
  # grant lands.
  is_bootstrap_only = length(var.statements) == 0

  bootstrap_statement = join("", [
    "allow any-user to inspect compartments in compartment id ${var.compartment_id} where request.principal.type='cluster'",
  ])

  raw_statements = local.is_bootstrap_only ? [local.bootstrap_statement] : var.statements

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

  # A statement that says `any-user` without pinning the cluster principal type
  # is a grant to EVERY principal in the tenancy. This is the sharpest guard and
  # why this object is separate from oke-workload-identity (which pins
  # `type='workload'`): a statement that drops the principal type entirely must
  # never pass either.
  statements_without_cluster_principal = [
    for s in local.all_statements : s
    if length(regexall("any-user", s)) > 0 && length(regexall("request\\.principal\\.type='cluster'", s)) == 0
  ]

  # `in compartment <name>` is lowercased server-side; `in compartment id
  # <ocid>` is not. Only the latter is diff-stable.
  statements_with_named_compartment = [
    for s in local.all_statements : s
    if length(regexall(" in compartment ", s)) > 0 && length(regexall(" in compartment id ", s)) == 0
  ]
}