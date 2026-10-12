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

  # ---------------------------------------------------------------------------
  # THE GRANT LIST - check sheet section 10.
  #
  # ONE grant. That is not an omission; it is the corrected finding. The AWS
  # module has no hardcoded policy at all, and its single real instantiation
  # sets `aws_managed_policy_names = []` and `customer_managed_policy_arns = []`
  # with exactly one `inline_policies` entry: `kms-encrypt-decrypt` on
  # HYPERSWITCH's key. identity-model.md section 1.2 estimated 6 grants here by
  # analogy to `grafana` ("same broad set... shared module lineage"); the
  # analogy does not hold, and the check sheet's section 10 records the
  # correction (6 -> 1), the largest single correction in that batch.
  # ---------------------------------------------------------------------------
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

  # ---------------------------------------------------------------------------
  # THE STATEMENT RENDERER.
  #
  # THIS MODULE CREATES NO `oci_identity_policy`, and that is structural.
  # `oci_identity_policy.name` is tenancy-unique AND non-updatable; one object
  # per app per live root is 12 apps x 11 roots = 132 objects against a hard
  # limit of 100 (identity-model.md section 3.7). The platform runs ONE shared
  # policy object per environment, owned by `oke-workload-identity`, into which
  # every app module contributes STATEMENTS. This module's contribution is the
  # `policy_statements` output.
  #
  # The four `where all {}` conditions ARE the security boundary
  # (identity-model.md section 3.2). On AWS a malformed trust policy fails
  # CLOSED; on OCI a statement missing `request.principal.cluster_id` grants
  # every cluster in the tenancy, and one missing
  # `request.principal.service_account` grants every pod in the namespace -
  # silently, with no API error. All four conditions are hard-coded into the
  # template below and are not caller-controllable, and `oke-workload-identity`
  # re-validates everything contributed to it at plan time.
  #
  # Text is pre-normalised and sorted, because the OCI API rewrites statement
  # text server-side and anything not already in normal form is a permanent
  # Terraform diff (oracle/terraform-provider-oci#371). Only
  # `in compartment id <ocid>` is emitted - compartment NAMES get lowercased.
  # ---------------------------------------------------------------------------
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
