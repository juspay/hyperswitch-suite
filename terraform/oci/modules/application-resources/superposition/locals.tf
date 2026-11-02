locals {
  name_prefix = "${var.environment}-${var.project_name}"

  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "superposition"
      managed_by  = "terraform"
    },
    var.freeform_tags
  )

  # ONE grant - the corrected finding. The AWS module has no hardcoded policy;
  # its single live grant is `use keys` on hyperswitch's key.
  kms_grant_enabled = var.kms_key_id != null

  grants = concat(
    local.kms_grant_enabled ? [{
      verb          = "use"
      resource_type = "keys"
      location      = var.compartment_id
      # Scoped to hyperswitch's specific key rather than the compartment: a
      # compartment-wide `use keys` here would also reach the database
      # credential key and anything else in the same compartment, which is
      # wider than the AWS inline policy it replaces.
      condition = "target.key.id='${var.kms_key_id}'"
    }] : [],
  )

  # THIS MODULE CREATES NO `oci_identity_policy` - it contributes statements to
  # the one shared environment-scoped object owned by oke-workload-identity. The
  # four `where all {}` conditions ARE the security boundary (fails open on OCI
  # if dropped); text is pre-normalised so the API cannot rewrite it into a
  # perpetual diff.
  statement_tuples = flatten([
    for g in local.grants : [
      for sa in var.service_accounts : [
        for cluster_id in var.cluster_ids : join("", [
          "allow any-user to ${lower(trimspace(g.verb))} ${lower(trimspace(g.resource_type))} in compartment id ${g.location} where all {",
          "request.principal.type='workload',",
          "request.principal.namespace='${lower(trimspace(sa.namespace))}',",
          "request.principal.service_account='${lower(trimspace(sa.name))}',",
          "request.principal.cluster_id='${cluster_id}'",
          g.condition == null ? "" : ",${trimspace(g.condition)}",
          "}",
        ])
      ]
    ]
  ])

  policy_statements = sort(distinct([
    for s in concat(local.statement_tuples, var.extra_statements) :
    replace(
      replace(
        replace(
          replace(trimspace(s), "/\\s+/", " "),
        "/\\s*(!?=)\\s*/", "$1"),
      "/,\\s+/", ","),
    "/\\{\\s+|\\s+\\}/", "")
  ]))

  authorized_workloads = distinct(flatten([
    for sa in var.service_accounts : [
      for cluster_id in var.cluster_ids : {
        cluster_id      = cluster_id
        namespace       = lower(trimspace(sa.namespace))
        service_account = lower(trimspace(sa.name))
      }
    ]
  ]))
}
