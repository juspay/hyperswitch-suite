locals {
  is_bootstrap_only = length(var.statements) == 0

  bootstrap_statement = join("", [
    "Allow service opensearch to inspect compartments in compartment id ${var.compartment_id}",
  ])

  raw_statements = local.is_bootstrap_only ? [local.bootstrap_statement] : var.statements

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

  statements_without_opensearch_principal = [
    for s in local.all_statements : s
    if length(regexall("(?i)service opensearch", s)) == 0
  ]

  statements_with_named_compartment = [
    for s in local.all_statements : s
    if length(regexall(" in compartment ", s)) > 0 && length(regexall(" in compartment id ", s)) == 0
  ]
}
