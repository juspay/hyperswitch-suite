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

  # ---------------------------------------------------------------------------
  # Feature enablement, mirroring the AWS module's `try(var.x.create, false)`
  # count-gating pattern one-for-one so a reviewer can diff the two.
  # ---------------------------------------------------------------------------
  kms_create = coalesce(var.kms.create, true) && var.kms.existing_key_id == null
  kms_key_id = local.kms_create ? one(oci_kms_key.this[*].id) : var.kms.existing_key_id

  kms_replica_create = local.kms_create && coalesce(var.kms.create_replica, false)

  # SUBSTITUTE, check sheet section 4.1. `oci_kms_vault_replication` is
  # documented as "This only supports virtual private vault for now" - the
  # dedicated-HSM tier, a standing cost even in dev, and `vault_type` is not
  # updatable in place. So the vault type is forced by the DR posture rather
  # than being independently settable and silently wrong: asking for a replica
  # gets a virtual private vault whether or not the caller remembered to say so.
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
  email_create  = local.email_enabled && coalesce(var.email.create, true) && var.email.use_existing_domain_id == null

  email_domain_id = local.email_create ? one(oci_email_email_domain.this[*].id) : var.email.use_existing_domain_id
  email_sender_id = local.email_create ? one(oci_email_sender.this[*].id) : var.email.use_existing_sender_id

  secrets_enabled   = coalesce(var.secrets.enabled, true)
  functions_enabled = coalesce(var.functions.enabled, true)

  functions_compartment_id = coalesce(var.functions.compartment_id, var.compartment_id)

  # ---------------------------------------------------------------------------
  # THE GRANT LIST - check sheet section 10, one entry per row of that table.
  #
  # `location` is the `in compartment id <ocid>` term. `condition` is an extra
  # `where all {}` term appended AFTER the four principal conditions, written
  # pre-normalised.
  # ---------------------------------------------------------------------------
  grants = concat(
    # 1. kms:Decrypt + kms:Encrypt + kms:GenerateDataKey + kms:DescribeKey
    #    -> ONE verb. `use keys` = READ + KEY_ENCRYPT + KEY_DECRYPT + KEY_EXPORT
    #    + KEY_SIGN + KEY_VERIFY, so four AWS actions collapse into one OCI
    #    statement. Scoped to this specific key rather than the compartment,
    #    because a compartment-wide `use keys` would also cover the database
    #    credential key and any future key in the same compartment.
    local.kms_key_id != null ? [{
      verb          = "use"
      resource_type = "keys"
      location      = var.compartment_id
      condition     = "target.key.id='${local.kms_key_id}'"
    }] : [],

    # 2-3. s3:PutObject/GetObject (+ ListBucket, GetObjectVersion on bucket 2)
    #      -> `manage objects`, NOT `use objects`. PutObject needs
    #      OBJECT_CREATE when the object does not yet exist, and only `manage`
    #      grants it (identity-model.md section 3.5's trap). Version-aware reads
    #      have no separate verb; they are ordinary reads against a versioned
    #      bucket.
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

    # 4-5. secretsmanager:GetSecretValue -> `read secret-bundles` (the value);
    #      secretsmanager:DescribeSecret -> `read secrets` (the metadata).
    #      Both are needed; neither substitutes for the other.
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
    #    The account-wide list/create/code-signing actions are deliberately not
    #    reproduced (check sheet section 4.3, PARTIAL).
    local.functions_enabled ? [{
      verb          = "use"
      resource_type = "functions-family"
      location      = local.functions_compartment_id
      condition     = null
    }] : [],

    # 7. ses:SendEmail/SendTemplatedEmail/SendRawEmail/ListTemplates/
    #    ListVerifiedEmailAddresses -> `use email-family`.
    #
    #    UNCONFIRMED, and knowingly so (check sheet section 9 Q1/Q2). The email
    #    policy reference ties `use approved-senders` / `use email-family` to
    #    the SmtpSend operation and does not list the HTTPS `SubmitEmail`
    #    operation in its verb tables at all. This grant is emitted anyway,
    #    because the workload-identity path is the primary path by decision and
    #    an untested primary path that is never emitted is a path that never
    #    gets tested. If it turns out to be the wrong verb, this is the one line
    #    that changes.
    local.email_enabled ? [{
      verb          = "use"
      resource_type = "email-family"
      location      = var.compartment_id
      condition     = null
    }] : [],
  )

  # ---------------------------------------------------------------------------
  # THE STATEMENT RENDERER.
  #
  # THIS MODULE CREATES NO `oci_identity_policy`, AND THAT IS STRUCTURAL, NOT
  # STYLISTIC. `oci_identity_policy.name` is unique across the entire tenancy
  # AND not updatable. One policy object per app per live root at the current
  # footprint is 12 apps x 11 roots = 132 objects against a hard limit of 100
  # per tenancy - unbuildable - and discovering that after the first apply means
  # renaming, which destroys and recreates every identity in the tenancy with a
  # window in which every pod loses access (identity-model.md section 3.7).
  #
  # So the platform runs ONE shared policy object per environment, owned by the
  # standalone `oke-workload-identity` module and its catalog unit, and every
  # app module contributes STATEMENTS into it. This module's contribution is the
  # `policy_statements` output. Do not "simplify" this by adding a policy
  # resource here.
  #
  # The four `where all {}` conditions ARE the security boundary
  # (identity-model.md section 3.2). Drop `request.principal.cluster_id` and the
  # grant covers every cluster in the tenancy; drop
  # `request.principal.service_account` and it covers every pod in the
  # namespace. Both are accepted by the API without error: on AWS a malformed
  # trust policy fails CLOSED, on OCI a malformed statement fails OPEN. The four
  # conditions are hard-coded into the template below and are not
  # caller-controllable, and `oke-workload-identity` re-validates every
  # contributed statement at plan time (its main.tf preconditions).
  #
  # `any-user` is the subject because a workload has no group to name. Oracle
  # recommends against bare `any-user` and is right to - it covers every user,
  # instance, resource and service principal in the tenancy.
  # `request.principal.type='workload'` is the only thing that narrows it.
  #
  # Text is emitted pre-normalised and sorted: the OCI API rewrites statement
  # text server-side (collapses whitespace, strips spaces around `=`, lowercases
  # compartment NAMES) and anything not already in normal form is a permanent,
  # un-suppressable Terraform diff (oracle/terraform-provider-oci#371). Only
  # `in compartment id <ocid>` is emitted; OCIDs are not rewritten.
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

  # Audit surface: the (cluster, namespace, service_account) tuples authorised.
  # The replacement for the AWS module's `cluster_service_accounts` echo.
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
