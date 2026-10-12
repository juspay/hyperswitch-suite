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
  # THE GRANT LIST - check sheet section 10.
  # ---------------------------------------------------------------------------
  grants = concat(
    # 1. s3:PutObject + GetObject + ListBucket + DeleteObject + GetObjectVersion
    #    -> `manage objects`. Five AWS actions, one OCI verb. `read objects` for
    #    a consumer-only instantiation; a PRODUCER must have `manage`, because
    #    PutObject needs OBJECT_CREATE and neither `read` nor `use` grants it
    #    (identity-model.md section 3.5's trap).
    #
    #    Scoped by `target.bucket.name`: five vector instantiations share one
    #    compartment, and a compartment-wide grant would give each of them the
    #    other four's logs.
    var.create_bucket ? [{
      verb          = var.bucket_read_only ? "read" : "manage"
      resource_type = "objects"
      location      = var.compartment_id
      condition     = "target.bucket.name='${local.bucket_name}'"
    }] : [],

    # 2. Consume the event stream.
    #
    #    EMITTED, AND KNOWN NOT TO BE SUFFICIENT ON ITS OWN. `use stream-pull`
    #    is the IAM grant for pulling from a Streaming stream, and it works for
    #    an OCI-SDK client under workload identity. But Vector does not use the
    #    OCI SDK for this - it uses its `kafka` source against Streaming's
    #    Kafka-compatible endpoint, which authenticates with SASL/PLAIN and an
    #    OCI auth token and consults no `request.principal.*` condition at all.
    #
    #    The statement is emitted anyway, because it is correct, because it
    #    costs one line against a 50-statement budget, and because it is what
    #    the polling fallback (check sheet section 4.4 option 2) would need if
    #    the gate rejects the auth token. Do not read its presence as evidence
    #    that the Kafka path is authorised by it. See notification.tf.
    var.create_notification ? [{
      verb          = "use"
      resource_type = "stream-pull"
      location      = var.compartment_id
      condition     = null
    }] : [],

    # 3-4. Cross-region consumption (check sheet feature 6, PARTIAL).
    #      Ordinary cross-compartment statements; the part that does NOT work
    #      by IAM alone is the network path, because Streaming is regional
    #      rather than global like Pub/Sub. See the variable's own note.
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

  # ---------------------------------------------------------------------------
  # THE STATEMENT RENDERER.
  #
  # THIS MODULE CREATES NO `oci_identity_policy`, and that is structural.
  # `oci_identity_policy.name` is tenancy-unique AND non-updatable; one object
  # per app per live root is 132 objects against a hard limit of 100
  # (identity-model.md section 3.7). ONE shared policy object per environment,
  # owned by `oke-workload-identity`, receives statements from every app module.
  #
  # This module has the widest fan-out in the platform - five instantiations,
  # five near-identical statement sets - which makes the asymmetric failure mode
  # proportionally more dangerous here than anywhere else: on AWS a malformed
  # trust policy fails CLOSED, on OCI a statement missing
  # `request.principal.service_account` grants every pod in the namespace and
  # the API accepts it silently. All four `where all {}` conditions are
  # hard-coded below and are not caller-controllable, and
  # `oke-workload-identity` re-validates every contributed statement at plan
  # time.
  #
  # Pre-normalised and sorted (oracle/terraform-provider-oci#371). Only
  # `in compartment id <ocid>`; compartment NAMES are lowercased server-side.
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

  # ---------------------------------------------------------------------------
  # Events-rule condition.
  #
  # THE BUCKET-NAME FILTER IS NOT OPTIONAL, and this is the residual risk check
  # sheet section 4.4 ranks second. S3 attaches a notification config TO A
  # BUCKET. An OCI Events rule is scoped to a COMPARTMENT and its children, so a
  # rule intended for one bucket fires for EVERY object-storage event in the
  # compartment subtree unless `data.additionalDetails.bucketName` narrows it.
  # With five vector buckets plus loki's plus hyperswitch's two in one
  # compartment, an unfiltered rule is a firehose. Rendered unconditionally
  # below rather than left to a caller-supplied string.
  # ---------------------------------------------------------------------------
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
