locals {
  name_prefix = "${var.environment}-${var.project_name}"

  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "loki"
      managed_by  = "terraform"
    },
    var.freeform_tags
  )

  bucket_name = coalesce(var.bucket_name, "${local.name_prefix}-loki-chunks")

  nsg_display_name = coalesce(var.nsg_display_name, "${local.name_prefix}-loki-nsg")

  # ---------------------------------------------------------------------------
  # THE GRANT LIST - check sheet section 10. One grant, and that is the whole
  # identity surface of this module.
  #
  # AWS: s3:PutObject + GetObject + ListBucket + DeleteObject + GetObjectVersion
  # -> `manage objects`, NOT `use objects`. PutObject needs OBJECT_CREATE when
  # the object does not yet exist, and only `manage` grants it
  # (identity-model.md section 3.5's documented trap). Five AWS actions, one
  # OCI verb.
  #
  # Scoped by `target.bucket.name` rather than left compartment-wide, so a
  # compromised Loki cannot read `vector`'s or `hyperswitch`'s buckets in the
  # same compartment.
  # ---------------------------------------------------------------------------
  grants = var.create_bucket ? [{
    verb          = "manage"
    resource_type = "objects"
    location      = var.compartment_id
    condition     = "target.bucket.name='${local.bucket_name}'"
  }] : []

  # ---------------------------------------------------------------------------
  # THE STATEMENT RENDERER.
  #
  # THIS MODULE CREATES NO `oci_identity_policy`, and that is structural.
  # `oci_identity_policy.name` is tenancy-unique AND non-updatable; one object
  # per app per live root is 12 apps x 11 roots = 132 objects against a hard
  # limit of 100 per tenancy (identity-model.md section 3.7). ONE shared policy
  # object per environment, owned by `oke-workload-identity`, receives
  # statements from every app module. This module's contribution is the
  # `policy_statements` output.
  #
  # The four `where all {}` conditions ARE the security boundary
  # (identity-model.md section 3.2). This module's residual risk is lower than
  # most of its family - one service account, one grant, no fan-out to get
  # wrong - but the failure mode is the same and it is asymmetric: on AWS a
  # malformed trust policy fails CLOSED, on OCI a statement missing
  # `request.principal.service_account` grants every pod in the namespace and
  # the API accepts it without error. All four conditions are hard-coded below
  # and are not caller-controllable; `oke-workload-identity` re-validates every
  # contributed statement at plan time.
  #
  # Pre-normalised and sorted, because the API rewrites statement text
  # server-side and anything not already in normal form is a permanent
  # Terraform diff (oracle/terraform-provider-oci#371). Only
  # `in compartment id <ocid>` is emitted; compartment NAMES get lowercased.
  # ---------------------------------------------------------------------------
  statement_tuples = flatten([
    for g in local.grants : [
      for cluster_id in var.cluster_ids : join("", [
        "allow any-user to ${lower(trimspace(g.verb))} ${lower(trimspace(g.resource_type))} in compartment id ${g.location} where all {",
        "request.principal.type='workload',",
        "request.principal.namespace='${lower(trimspace(var.k8s_namespace))}',",
        "request.principal.service_account='${lower(trimspace(var.k8s_service_account_name))}',",
        "request.principal.cluster_id='${cluster_id}'",
        g.condition == null ? "" : ",${trimspace(g.condition)}",
        "}",
      ])
    ]
  ])

  policy_statements = sort(distinct([
    for s in concat(local.statement_tuples, var.shared_statements, var.extra_statements) :
    replace(
      replace(
        replace(
          replace(trimspace(s), "/\\s+/", " "),
        "/\\s*(!?=)\\s*/", "$1"),
      "/,\\s+/", ","),
    "/\\{\\s+|\\s+\\}/", "")
  ]))

  authorized_workloads = [
    for cluster_id in var.cluster_ids : {
      cluster_id      = cluster_id
      namespace       = lower(trimspace(var.k8s_namespace))
      service_account = lower(trimspace(var.k8s_service_account_name))
    }
  ]

  lifecycle_rules = var.bucket_lifecycle_expiry_days == null ? [] : [{
    name        = "expire-chunks"
    action      = "DELETE"
    time_amount = var.bucket_lifecycle_expiry_days
    time_unit   = "DAYS"
  }]
}
