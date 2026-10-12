locals {
  # Step 1 - render one statement per grant. Principal pinned by type +
  # domain.id + ext_iss + name(SA subject); no per-cluster enumeration (the
  # trust pins the EKS issuer).
  grant_tuples = [
    for g in var.workload_grants : {
      namespace       = lower(trimspace(g.namespace))
      service_account = lower(trimspace(g.service_account))
      verb            = lower(trimspace(g.verb))
      resource_type   = lower(trimspace(g.resource_type))
      location        = coalesce(g.compartment_id, var.compartment_id)
      condition       = g.condition == null ? "" : ",${trimspace(g.condition)}"
    }
  ]

  # request.principal.ext_iss = the EKS OIDC issuer, surfaced when "ext_iss" is
  # in claim_propagations. Hard-pins every grant to the exact trusted issuer so
  # a token from any other issuer is out of scope even on SA-name collision.
  # When not propagated, the audit guard below rejects every federated
  # statement, forcing propagation or an intentional drop of the issuer pin.
  ext_iss = contains(var.claim_propagations, "ext_iss") ? var.eks_oidc_issuer : null

  rendered_statements = [
    for t in local.grant_tuples :
    join("", [
      "allow any-user to ${t.verb} ${t.resource_type} in compartment id ${t.location} where all {",
      "request.principal.type='identityfederateddomainapp',",
      "request.principal.name='system:serviceaccount:${t.namespace}:${t.service_account}'",
      # ext_iss is the hard pin to the EKS issuer; omitted only when
      # claim_propagations lack ext_iss, which the audit guard rejects - kept
      # only so the renderer is total.
      local.ext_iss != null ? ",request.principal.ext_iss='${local.ext_iss}'" : "",
      t.condition,
      "}",
    ])
  ]

  composed_statements = concat(local.rendered_statements, var.statements)
  all_statements      = sort(distinct(local.composed_statements))

  # Step 2 - fail-open guards. A federated statement dropping any of the four
  # identity pins widens to every federated workload in the tenancy; abort the
  # plan rather than apply silently.

  fed_statements = [
    for s in local.all_statements : s
    if length(regexall("request\\.principal\\.type='identityfederateddomainapp'", s)) > 0
  ]

  statements_missing_type = [
    for s in local.all_statements : s
    if length(regexall("\\bany-user\\b", s)) > 0
    && length(regexall("request\\.principal\\.type='identityfederateddomainapp'", s)) == 0
    && length(regexall("request\\.principal\\.type='workload'", s)) == 0
    && length(regexall("request\\.principal\\.type='cluster'", s)) == 0
    && length(regexall("^allow service ", s)) == 0
  ]

  statements_missing_sa = [
    for s in local.fed_statements : s
    if length(regexall("request\\.principal\\.name='system:serviceaccount:[^']+:[^']+'", s)) == 0
  ]

  statements_missing_issuer = [
    for s in local.fed_statements : s
    if length(regexall("request\\.principal\\.ext_iss='[^']+'", s)) == 0
  ]

  statements_with_named_compartment = [
    for s in local.all_statements : s
    if length(regexall(" in compartment ", s)) > 0
    && length(regexall(" in compartment id ", s)) == 0
  ]

  # Step 3 - audit surface: the (namespace, service_account, verb, resource)
  # tuples this policy authorises, recovered from the final statement text so
  # contributed statements are covered too.
  authorized_workloads = distinct([
    for s in local.fed_statements : {
      namespace       = try(regexall("request\\.principal\\.name='system:serviceaccount:([^']+):[^']+'", s)[0][0], "UNPARSEABLE")
      service_account = try(regexall("request\\.principal\\.name='system:serviceaccount:[^']+:([^']+)'", s)[0][0], "UNPARSEABLE")
      verb            = try(regexall("allow any-user to ([a-z]+) ", s)[0][0], "UNPARSEABLE")
      resource_type   = try(regexall("allow any-user to [a-z]+ ([a-z-]+) in compartment", s)[0][0], "UNPARSEABLE")
    }
  ])
}