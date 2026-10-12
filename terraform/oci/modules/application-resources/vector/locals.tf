locals {
  name_prefix = "${var.environment}-${var.project_name}"

  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "vector"
      app         = var.app_name
      managed_by  = "terraform"
    },
    var.freeform_tags
  )

  bucket_name = coalesce(var.bucket_name, "${local.name_prefix}-${var.app_name}")
  stream_name = "${local.name_prefix}-${var.app_name}-events"

  cross_region_enabled = coalesce(var.cross_region_read.enabled, false)

  # ---------------------------------------------------------------------------
  # THE GRANT LIST
  # ---------------------------------------------------------------------------
  grants = concat(
    # 1. s3 PutObject/GetObject/ListBucket/DeleteObject/GetObjectVersion ->
    #    `manage objects`. A PRODUCER must have `manage`: PutObject needs
    #    OBJECT_CREATE, which neither `read` nor `use` grants. Scoped to this
    #    bucket so five instantiations sharing a compartment do not see each
    #    other's logs.
    var.create_bucket ? [{
      verb          = var.bucket_read_only ? "read" : "manage"
      resource_type = "objects"
      location      = var.compartment_id
      condition     = "target.bucket.name='${local.bucket_name}'"
    }] : [],

    # 2. Consume the event stream. `use stream-pull` is correct IAM but does NOT
    #    authorise Vector's Kafka client, which authenticates with SASL/PLAIN
    #    over Streaming's Kafka endpoint and consults no request.principal.*
    #    condition. Emitted for the polling fallback; see notification.tf.
    var.create_notification ? [{
      verb          = "use"
      resource_type = "stream-pull"
      location      = var.compartment_id
      condition     = null
    }] : [],

    # 3-4. Cross-region consumption. The IAM half only - Streaming is regional,
    #      so a network path must be decided separately.
    local.cross_region_enabled && var.cross_region_read.bucket_compartment_id != null ? [{
      verb          = "read"
      resource_type = "objects"
      location      = var.cross_region_read.bucket_compartment_id
      condition     = var.cross_region_read.bucket_name == null ? null : "target.bucket.name='${var.cross_region_read.bucket_name}'"
    }] : [],

    local.cross_region_enabled && var.cross_region_read.stream_compartment_id != null ? [{
      verb          = "use"
      resource_type = "stream-pull"
      location      = var.cross_region_read.stream_compartment_id
      condition     = null
    }] : [],
  )

  # THIS MODULE CREATES NO `oci_identity_policy`, and that is structural: `name`
  # is tenancy-unique and non-updatable, and one object per app per root exceeds
  # the hard 100-per-tenancy limit. ONE shared policy object per environment
  # (owned by `oke-workload-identity`) receives statements from every app module.
  #
  # The four `where all {}` conditions ARE the security boundary and are
  # hard-coded below. On AWS a malformed trust policy fails CLOSED; on OCI a
  # statement missing request.principal.service_account grants every pod in the
  # namespace and the API accepts it silently - with five near-identical
  # instantiations this is the widest fan-out in the platform.
  #
  # Pre-normalised and sorted: the API rewrites statement text server-side, so
  # anything not in normal form is a permanent diff. Only `in compartment id <ocid>`.
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

  # Events-rule condition. The bucket-name filter is not optional: an OCI Events
  # rule is scoped to a COMPARTMENT and its children, so without it a rule for
  # one bucket fires for every object-storage event in the subtree (five vector
  # buckets plus loki's plus hyperswitch's two here). Rendered unconditionally.
  event_condition = jsonencode(merge(
    {
      eventType = var.event_types
      data = merge(
        { additionalDetails = { bucketName = [local.bucket_name] } },
        var.event_object_name_prefix == null ? {} : { resourceName = ["${var.event_object_name_prefix}*"] }
      )
    }
  ))

  uses_static_kafka_credential = var.create_notification && var.auth_token_vault_secret_id != null
}
