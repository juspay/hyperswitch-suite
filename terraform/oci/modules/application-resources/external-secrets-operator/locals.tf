# Grant list and statement renderer.
# This module renders statements and creates no `oci_identity_policy`: the
# platform runs ONE shared policy object per environment (owned by
# `oke-workload-identity`) into which app modules contribute statements. This
# renderer is a copy of that module's locals.tf, and everything it emits is
# re-validated at plan time by that module's preconditions - statement text is
# a security boundary, not a formatting concern.

locals {
  name_prefix = "${var.project_name}-${var.environment}-eso"

  # Where the secrets live. Defaults to the environment compartment.
  secrets_compartment_id = coalesce(var.vault_compartment_id, var.compartment_id)

  common_freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "external-secrets-operator"
      managed_by  = "terraform"
    },
    var.region != null ? { region = var.region } : {},
    var.freeform_tags
  )

  # The two grants, and why they are two.
  #   GetSecretValue -> read secret-bundles  (SECRET_BUNDLE_READ)
  #   DescribeSecret -> read secrets         (SECRET_READ)
  # `read secrets` is NOT enough to read a secret - it returns metadata only.
  # ESO calls both, so both are here. The single-line `read secret-family`
  # alternative also grants `secret-versions`, which the AWS inline policy does
  # not - broader, not equivalent.
  base_resource_types = ["secret-bundles", "secrets"]

  # Per-secret scoping is opt-in. Empty secret_ids -> compartment-wide, which is
  # the AWS behaviour (`secret:*`). No configuration grants nothing.
  base_grants = flatten([
    for rt in local.base_resource_types : (
      length(var.secret_ids) == 0
      ? [{
        verb           = "read"
        resource_type  = rt
        compartment_id = local.secrets_compartment_id
        condition      = null
      }]
      : [for sid in var.secret_ids : {
        verb           = "read"
        resource_type  = rt
        compartment_id = local.secrets_compartment_id
        condition      = "target.secret.id='${sid}'"
      }]
    )
  ])

  all_grants = concat(local.base_grants, [
    for g in var.additional_grants : {
      verb           = g.verb
      resource_type  = g.resource_type
      compartment_id = coalesce(g.compartment_id, var.compartment_id)
      condition      = g.condition
    }
  ])

  # Render: one statement per (grant x cluster). One namespace, one service
  # account - flattened to scalars because the live layer has only ever used one pair.
  grant_tuples = flatten([
    for g in local.all_grants : [
      for cluster_id in var.cluster_ids : {
        cluster_id      = cluster_id
        namespace       = lower(trimspace(var.k8s_namespace))
        service_account = lower(trimspace(var.k8s_service_account_name))
        verb            = lower(trimspace(g.verb))
        resource_type   = lower(trimspace(g.resource_type))
        location        = g.compartment_id
        condition       = g.condition == null ? "" : ",${trimspace(g.condition)}"
      }
    ]
  ])

  rendered_statements = [
    for t in local.grant_tuples : join("", [
      "allow any-user to ${t.verb} ${t.resource_type} in compartment id ${t.location} where all {",
      "request.principal.type='workload',",
      "request.principal.namespace='${t.namespace}',",
      "request.principal.service_account='${t.service_account}',",
      "request.principal.cluster_id='${t.cluster_id}'",
      t.condition,
      "}",
    ])
  ]

  # Four normalisation rules: the OCI API rewrites statement text server-side, so
  # anything not in normal form is a perpetual diff.
  policy_statements = sort(distinct([
    for s in concat(local.rendered_statements, var.shared_statements, var.extra_statements) :
    replace(
      replace(
        replace(
          replace(trimspace(s), "/\\s+/", " "),
        "/\\s*(!?=)\\s*/", "$1"),
      "/,\\s+/", ","),
    "/\\{\\s+|\\s+\\}/", "")
  ]))

  # The structured form of the same grants, for callers wiring
  # `oke-workload-identity.workload_grants` instead of `.statements`.
  workload_grants = [
    for g in local.all_grants : {
      namespace       = lower(trimspace(var.k8s_namespace))
      service_account = lower(trimspace(var.k8s_service_account_name))
      verb            = lower(trimspace(g.verb))
      resource_type   = lower(trimspace(g.resource_type))
      compartment_id  = g.compartment_id
      condition       = g.condition
    }
  ]

  authorized_workloads = [
    for cluster_id in var.cluster_ids : {
      cluster_id      = cluster_id
      namespace       = lower(trimspace(var.k8s_namespace))
      service_account = lower(trimspace(var.k8s_service_account_name))
    }
  ]
}
