locals {
  name_prefix = "${var.environment}-${var.project_name}"

  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "decision-engine"
      managed_by  = "terraform"
    },
    var.freeform_tags
  )

  bucket_create = coalesce(var.bucket.create, true)

  # No region suffix - OCI bucket names are unique within the tenancy's Object
  # Storage namespace, so the suffix's global-collision purpose is already met.
  bucket_name = coalesce(var.bucket.bucket_name, "${local.name_prefix}-decision-engine")

  # The AWS unit's single 30-day noncurrent-version-expiration rule plus anything
  # the caller adds. A separate resource on OCI, not an inline block on the bucket.
  noncurrent_version_rules = var.bucket_noncurrent_version_expiry_days == null ? [] : [{
    name               = "expire-noncurrent-versions"
    action             = "DELETE"
    time_amount        = var.bucket_noncurrent_version_expiry_days
    time_unit          = "DAYS"
    target             = "previous-object-versions"
    is_enabled         = true
    object_name_filter = null
  }]

  lifecycle_rules = concat(local.noncurrent_version_rules, var.bucket.lifecycle_rules)

  email_enabled = coalesce(var.email.enabled, true)
  email_create  = local.email_enabled && coalesce(var.email.create, false) && var.email.use_existing_domain_id == null

  email_domain_id = local.email_create ? one(oci_email_email_domain.this[*].id) : var.email.use_existing_domain_id
  email_sender_id = local.email_create ? one(oci_email_sender.this[*].id) : var.email.use_existing_sender_id

  # THE GRANT LIST. Three grants.
  grants = concat(
    # 1. kms:Decrypt + kms:Encrypt on HYPERSWITCH's key (this module owns none).
    #    `use keys` covers both, scoped to the key rather than the compartment.
    var.kms_key_id != null ? [{
      verb          = "use"
      resource_type = "keys"
      location      = var.compartment_id
      condition     = "target.key.id='${var.kms_key_id}'"
    }] : [],

    # 2. s3 PutObject/GetObject/ListBucket/GetObjectVersion/DeleteObject/GetBucketLocation
    #    -> `manage objects`: create, overwrite, delete and inspect are all part
    #    of `manage`, and PutObject needs OBJECT_CREATE, which read/use do not grant.
    local.bucket_create ? [{
      verb          = "manage"
      resource_type = "objects"
      location      = var.compartment_id
      condition     = "target.bucket.name='${local.bucket_name}'"
    }] : [],

    # 3. ses:SendEmail etc -> `use email-family`; the cross-account STS hop is
    #    dropped. UNCONFIRMED in the same way hyperswitch's is: the email policy
    #    reference ties this verb to SmtpSend and does not list the HTTPS
    #    SubmitEmail operation. Emitted anyway as the primary workload-identity path.
    local.email_enabled ? [{
      verb          = "use"
      resource_type = "email-family"
      location      = var.compartment_id
      condition     = null
    }] : [],
  )

  # THIS MODULE CREATES NO `oci_identity_policy`, and that is structural: `name`
  # is tenancy-unique and non-updatable, and one object per app per root exceeds
  # the hard 100-per-tenancy limit. ONE shared policy object per environment
  # (owned by `oke-workload-identity`) receives statements from every app module.
  #
  # The four `where all {}` conditions ARE the security boundary and are
  # hard-coded below, not caller-controllable. On AWS a malformed trust policy
  # fails CLOSED; on OCI a missing request.principal.cluster_id grants every
  # cluster in the tenancy and one missing service_account grants every pod in
  # the namespace, silently.
  #
  # Pre-normalised and sorted: the API rewrites statement text server-side, so
  # anything not found in normal form is a permanent diff. Only `in compartment id <ocid>`.
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
