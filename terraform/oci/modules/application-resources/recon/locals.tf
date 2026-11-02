locals {
  name_prefix = "${var.environment}-${var.project_name}"

  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "recon"
      managed_by  = "terraform"
    },
    var.freeform_tags
  )

  kms_create = coalesce(var.kms.create, true) && var.kms.existing_key_id == null
  kms_key_id = local.kms_create ? one(oci_kms_key.this[*].id) : var.kms.existing_key_id

  kms_replica_create = local.kms_create && coalesce(var.kms.create_replica, false)

  # vault_type is forced by the DR posture: replication requires a virtual
  # private vault and vault_type is not updatable in place.
  vault_type      = (local.vault_needs_vpv ? "VIRTUAL_PRIVATE" : "DEFAULT")
  vault_needs_vpv = coalesce(var.kms.use_virtual_private_vault, false) || coalesce(var.kms.create_replica, false)

  recon_bucket_create = coalesce(var.recon_bucket.create, true)

  recon_bucket_name = coalesce(
    var.recon_bucket.bucket_name,
    "${local.name_prefix}-recon"
  )

  secrets_enabled = coalesce(var.secrets.enabled, true)

  # One entry per policy the AWS module attaches to the recon IRSA role. The
  # Lambda invoke policy is NOT ported: report generation moves to invokr.
  grants = concat(
    # 1. recon_kms: kms:Decrypt + kms:Encrypt collapse into one OCI verb
    #    `use keys`, scoped to recon's own key rather than the compartment so
    #    it does not cover hyperswitch's or any other key.
    local.kms_key_id != null ? [{
      verb          = "use"
      resource_type = "keys"
      location      = var.compartment_id
      condition     = "target.key.id='${local.kms_key_id}'"
    }] : [],

    # 2. recon_s3: GetObject/PutObject/ListBucket -> `manage objects`, NOT
    #    `use objects`: PutObject needs OBJECT_CREATE when the object does not
    #    yet exist, and only `manage` grants it.
    local.recon_bucket_create ? [{
      verb          = "manage"
      resource_type = "objects"
      location      = var.compartment_id
      condition     = "target.bucket.name='${local.recon_bucket_name}'"
    }] : [],

    # 3-4. recon_secrets_manager: GetSecretValue -> `read secret-bundles`
    #      (value); DescribeSecret -> `read secrets` (metadata). Both needed;
    #      neither substitutes for the other.
    local.secrets_enabled ? flatten([
      for rt in ["secret-bundles", "secrets"] : (
        length(var.secrets.secret_ids) > 0
        ? [for sid in var.secrets.secret_ids : {
          verb          = "read"
          resource_type = rt
          location      = var.compartment_id
          condition     = "target.secret.id='${sid}'"
        }]
        : [{
          verb          = "read"
          resource_type = rt
          location      = var.compartment_id
          condition     = null
        }]
      )
    ]) : [],
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
