locals {
  # ---------------------------------------------------------------------------
  # Bootstrap.
  #
  # `oci_identity_policy.statements` is required and an empty policy is not a
  # thing the API accepts, but this policy object must exist from the moment the
  # first cluster is created - so that its tenancy-unique, NON-UPDATABLE name is
  # claimed once and never has to change. This statement is inert: it allows the
  # (real) cluster principal to `inspect compartments`, which returns metadata
  # only and is the narrowest possible permission. It is emitted only while
  # `statements` is empty and vanishes on the plan that adds the first real
  # grant - no flag to remember to flip.
  # ---------------------------------------------------------------------------
  is_bootstrap_only = length(var.statements) == 0

  bootstrap_statement = join("", [
    "allow any-user to inspect compartments in compartment id ${var.compartment_id} where request.principal.type='cluster'",
  ])

  raw_statements = local.is_bootstrap_only ? [local.bootstrap_statement] : var.statements

  # ---------------------------------------------------------------------------
  # Normalisation.
  #
  # The OCI API rewrites policy statement text server-side - it collapses
  # whitespace between keywords and strips spaces inside `where` clauses - which
  # produces a permanent, un-suppressable Terraform diff (oracle/terraform-
  # provider-oci#371). Four rules, matching oke-workload-identity/locals.tf:
  #   1. runs of whitespace collapse to a single space;
  #   2. spaces around `=` and `!=` are removed;
  #   3. a space after a comma is removed;
  #   4. spaces just inside `{` and `}` are removed.
  # Named compartment NAMES are designed out (see guards below) - only `in
  # compartment id <ocid>` is ever emitted. OCIDs are not rewritten.
  #
  # `sort` + `distinct` give a stable plan regardless of caller ordering.
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
  # Fail-open guards. Evaluated as resource preconditions in main.tf so they
  # abort the PLAN rather than the apply.
  # ---------------------------------------------------------------------------

  # A statement that says `any-user` without pinning the cluster principal type
  # is a grant to EVERY principal in the tenancy (user, instance, resource and
  # service principal). This is the sharpest guard in the module and the reason
  # this object is separate from oke-workload-identity: that module pins
  # `request.principal.type='workload'`, this one pins `...='cluster'`, and a
  # statement that drops the principal type entirely must never pass either.
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