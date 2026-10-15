locals {
  name_prefix = "${var.environment}-${var.project_name}"

  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "hyperswitch"
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

  dashboard_themes_create = coalesce(var.dashboard_themes_bucket.create, true)
  file_uploads_create     = coalesce(var.file_uploads_bucket.create, true)

  dashboard_themes_bucket_name = coalesce(
    var.dashboard_themes_bucket.bucket_name,
    "${local.name_prefix}-dashboard-themes"
  )
  file_uploads_bucket_name = coalesce(
    var.file_uploads_bucket.bucket_name,
    "${local.name_prefix}-file-uploads"
  )

  email_enabled = coalesce(var.email.enabled, true)
  # The domain/sender objects now live in the shared email-delivery module; the
  # module resolves created-vs-supplied internally and re-exposes the OCIDs.
  email_domain_id = module.email-delivery.email_domain_id
  email_sender_id = module.email-delivery.email_sender_id

  secrets_enabled   = coalesce(var.secrets.enabled, true)
  functions_enabled = coalesce(var.functions.enabled, true)

  functions_compartment_id = coalesce(var.functions.compartment_id, var.compartment_id)

  grants = concat(
    # 1. Four AWS KMS actions collapse into one OCI verb `use keys`, scoped to
    #    this key rather than the compartment so it does not cover other keys.
    local.kms_key_id != null ? [{
      verb          = "use"
      resource_type = "keys"
      location      = var.compartment_id
      condition     = "target.key.id='${local.kms_key_id}'"
    }] : [],

    # 2-3. PutObject/GetObject -> `manage objects`, NOT `use objects`: PutObject
    #      needs OBJECT_CREATE when the object does not yet exist, and only
    #      `manage` grants it. Version-aware reads are ordinary reads.
    local.dashboard_themes_create ? [{
      verb          = "manage"
      resource_type = "objects"
      location      = var.compartment_id
      condition     = "target.bucket.name='${local.dashboard_themes_bucket_name}'"
    }] : [],

    local.file_uploads_create ? [{
      verb          = "manage"
      resource_type = "objects"
      location      = var.compartment_id
      condition     = "target.bucket.name='${local.file_uploads_bucket_name}'"
    }] : [],

    # 4-5. GetSecretValue -> `read secret-bundles` (value); DescribeSecret ->
    #      `read secrets` (metadata). Both needed; neither substitutes for the other.
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

    # 6. lambda:InvokeFunction -> `use functions-family`, compartment-scoped.
    #    The account-wide list/create/code-signing actions are not reproduced.
    local.functions_enabled ? [{
      verb          = "use"
      resource_type = "functions-family"
      location      = local.functions_compartment_id
      condition     = null
    }] : [],

    # 7. SES send verbs -> `use email-family`. The HTTPS SubmitEmail operation
    #    is not listed in the email policy reference, but the workload-identity
    #    grant is emitted anyway as the primary path.
    local.email_enabled ? [{
      verb          = "use"
      resource_type = "email-family"
      location      = var.compartment_id
      condition     = null
    }] : [],
  )

  # THIS MODULE CREATES NO `oci_identity_policy`, and that is structural: `name`
  # is tenancy-unique and non-updatable, and one object per app per root exceeds
  # the hard 100-per-tenancy limit. The platform runs ONE shared policy object
  # per environment (owned by `oke-workload-identity`); this module contributes
  # STATEMENTS into it via the `policy_statements` output.
  #
  # The four `where all {}` conditions ARE the security boundary and are
  # hard-coded below, not caller-controllable. On AWS a malformed trust policy
  # fails CLOSED; on OCI a malformed statement fails OPEN (e.g. dropping the
  # service-account condition grants every pod in the namespace, silently).
  # `any-user` is narrowed only by request.principal.type='workload'.
  #
  # Statement text is pre-normalised and sorted because the OCI API rewrites it
  # server-side; anything not already in normal form is a permanent Terraform
  # diff. Only `in compartment id <ocid>` is emitted.
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

  # Audit surface: the (cluster, namespace, service_account) tuples authorised.
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
