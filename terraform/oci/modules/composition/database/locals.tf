locals {
  name_prefix = "${var.environment}-${var.project_name}"

  display_name = coalesce(var.display_name, "${local.name_prefix}-pgsql")

  # OCI has two tag namespaces where AWS has one. freeform_tags is the
  # tags_all analogue; defined_tags is passed through untouched because it
  # requires a tag namespace that this module does not own.
  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "database"
      managed_by  = "terraform"
    },
    var.freeform_tags
  )

  # ---------------------------------------------------------------------------
  # Storage placement (C13 - see the banner on storage_details in main.tf)
  # ---------------------------------------------------------------------------
  # is_regionally_durable is NOT a durability dial with a "more" and a "less"
  # setting. It selects between the service's two DATA PLACEMENT MODELS:
  #
  #   true  -> regional block volume;   "Nodes are placed in different
  #            availability domains."
  #   false -> AD-local block volume;   "Nodes are placed in different fault
  #            domains in the same availability domain."
  #
  # In a region with one AD the first model has nothing to express, and the API
  # says so rather than downgrading silently:
  #
  #   400-InvalidParameter, Invalid isRegionallyDurable: isRegionallyDurable is
  #   set to true but either the region or the service doesn't support this
  #   feature. This feature is only supported in 3 AD regions. Please set the
  #   parameter as false and specify availabilityDomain.
  #
  # So false + an explicit AD is not a weaker configuration than true in
  # ap-mumbai-1 - it is the only expressible one, and it describes exactly the
  # placement true would have produced if it had been accepted: the nodes spread
  # across the three fault domains of the single AD either way. What is lost is
  # nothing physical; it is the pretence that the config was portable.
  availability_domain_names = [
    for ad in data.oci_identity_availability_domains.this.availability_domains : ad.name
  ]

  availability_domain_count = length(local.availability_domain_names)

  # Explicit override wins; otherwise index 0, which in a single-AD region is
  # the only entry. Null when regionally durable, because the provider forbids
  # the pair in that direction ("If isRegionallyDurable is set to true,
  # availabilityDomain should not be specified").
  availability_domain = (
    var.is_regionally_durable ? null :
    var.availability_domain != null ? var.availability_domain :
    try(local.availability_domain_names[0], null)
  )

  # ---------------------------------------------------------------------------
  # Cross-region DR posture (SUBSTITUTE - check sheet features 6 and 7)
  # ---------------------------------------------------------------------------
  # There is no oci_psql_db_system counterpart to aws_rds_global_cluster: no
  # global object, no global identifier, no storage-layer replication. The only
  # mechanism OCI offers is Replication with Warm Standby - two independent db
  # systems in a PostgreSQL WAL-streaming relationship.
  #
  # It is OFF by default (var.enable_warm_standby = false) and that default is
  # deliberate for the dev cut, because turning it on buys a materially worse
  # DR contract than Aurora Global Database and costs a second full db system:
  #
  #   * RPO floor is 300 s (default 300, max 10800). Aurora's enforceable floor
  #     is 20 s and its observed lag is sub-second. On an unplanned regional
  #     failover this is up to five minutes of committed payments, not one
  #     second.
  #   * Failover is MANUAL. "Automatic failover isn't supported." RTO becomes
  #     however long it takes to page a human, versus Aurora's "less than 1
  #     minute".
  #   * With is_rpo_enforced = true the loss is bounded, but the primary
  #     switches to READ-ONLY when lag exceeds the threshold - a DR feature that
  #     can cause a payments outage. With it false the loss window is unbounded.
  #     There is no third setting.
  #   * Enabling it forfeits restore entirely (see var.source_backup_id /
  #     var.source_pitr and the precondition in outputs.tf).
  #
  # See docs/multi-cloud-parity/oci/data-tier-strategy.md - the binding decision
  # is Option B for dev (in-region HA + cross-region backup copy) with this path
  # written and validated but not instantiated.
  is_standby = var.enable_warm_standby

  # PARTIAL (check sheet feature 10, section 4.8): restore and warm standby are
  # mutually exclusive on the same db system. Exactly one source block may be
  # emitted; outputs.tf carries the precondition that rejects a combination.
  source_kind = (
    local.is_standby ? "DB_SYSTEM" : (
      var.source_backup_id != null ? "BACKUP" : (
        var.source_pitr != null ? "POINT_IN_TIME_DB_SYSTEM" : null
      )
    )
  )

  # ---------------------------------------------------------------------------
  # Admin credentials (PARTIAL - check sheet feature 12, section 4.10)
  # ---------------------------------------------------------------------------
  # OCI has no manage_master_user_password: credentials.password_details with
  # password_type = VAULT_SECRET only READS a secret the caller already created,
  # and nothing rotates it. So the module generates the password itself and
  # optionally writes it to OCI Vault - the direct descendant of
  # gcp/modules/composition/alloydb's random_password + Secret Manager pattern,
  # which hit the identical gap on AlloyDB.
  #
  # A warm standby needs no credentials block at all: "Users and roles are
  # replicated from the primary ... The warm standby database can't have
  # dedicated users or roles."
  generate_password = !local.is_standby && var.admin_password == null
  admin_password    = local.is_standby ? null : (local.generate_password ? random_password.admin[0].result : var.admin_password)

  vault_secret_create = var.vault_secret != null ? (var.vault_secret.create && !local.is_standby) : false
  vault_secret_name   = local.vault_secret_create ? coalesce(var.vault_secret.secret_name, "${local.display_name}-admin-password") : null

  # VAULT_SECRET when the module owns a Vault secret, PLAIN_TEXT otherwise.
  # PLAIN_TEXT still never carries a literal - the value is either generated
  # here or handed in by the caller from its own secret store.
  password_type = local.vault_secret_create ? "VAULT_SECRET" : "PLAIN_TEXT"

  # ---------------------------------------------------------------------------
  # Network access-control object (FULL - check sheet feature 16)
  # ---------------------------------------------------------------------------
  # The NSG is the closer analogue of an AWS security group than a VCN security
  # list is (membership-based, referenceable as a rule source). Like the AWS
  # module, this module owns the empty NSG and exports its OCID; the rules are
  # written by the security-last phase unit, not here.
  nsg_ids = compact(concat(
    var.create_nsg ? [oci_core_network_security_group.this[0].id] : [],
    var.nsg_ids
  ))

  # ---------------------------------------------------------------------------
  # Shape resolution (C9 - see the banner in configuration.tf)
  # ---------------------------------------------------------------------------
  # var.shape is the ListShapes `id` (the PostgreSQL.-prefixed string that
  # oci_psql_db_system.shape takes). oci_psql_configuration.shape takes the
  # SAME record's `shape` field, un-prefixed. Both are read off the service
  # rather than derived by string surgery, because the prefix is a naming
  # convention and not a contract.
  psql_shapes_by_id = {
    for s in flatten([for c in data.oci_psql_shapes.available.shape_collection : c.items]) :
    s.id => s
  }

  psql_shape = lookup(local.psql_shapes_by_id, var.shape, null)

  # Non-null only when var.shape is a shape this region actually offers. The
  # precondition on oci_psql_db_system.this rejects the null case at plan time;
  # these two fall back so that expression evaluation reaches that precondition
  # with a readable message instead of failing on a null attribute first.
  configuration_shape       = try(local.psql_shape.shape, null)
  configuration_is_flexible = try(local.psql_shape.is_flexible, false)

  # ---------------------------------------------------------------------------
  # Flexible-shape sizing bounds (C14 audit - C13's class, not C14's own)
  # ---------------------------------------------------------------------------
  # instance_ocpu_count and instance_memory_size_in_gbs are plain numbers that
  # `terraform validate` accepts unconditionally and that no provider schema
  # constrains, and their legal range is a property of THIS REGION'S shape
  # catalogue. That is exactly the shape of C13's isRegionallyDurable bug: it
  # passes validate, passes plan, and fails minutes into a create.
  #
  # The live ap-mumbai-1 record for PostgreSQL.VM.Standard.E5.Flex, read out of
  # data.oci_psql_shapes rather than from documentation:
  #
  #   shape_ocpu_options   { min = 1,  max = 64 }
  #   shape_memory_options { min_in_gbs = 16, max_in_gbs = 1024,
  #                          min_per_ocpu_in_gbs = 1, max_per_ocpu_in_gbs = 64,
  #                          default_per_ocpu_in_gbs = 16 }
  #
  # The module's 2 OCPU / 32 GB is 16 GB per OCPU - the record's own
  # default_per_ocpu_in_gbs, and inside every bound. So this guard does not
  # change the current plan; it makes the next sizing edit fail at plan.
  #
  # Both option lists are EMPTY on the fixed-size shape ids (is_flexible =
  # false, e.g. PostgreSQL.VM.Standard.E5.Flex.2.32GB), where sizing is baked
  # into the id. The try() therefore yields null and the guards no-op rather
  # than firing spuriously on a shape whose bounds the service does not publish.
  shape_ocpu_options   = try(local.psql_shape.shape_ocpu_options[0], null)
  shape_memory_options = try(local.psql_shape.shape_memory_options[0], null)

  ocpu_count_in_range = (
    local.shape_ocpu_options == null ? true :
    var.instance_ocpu_count >= local.shape_ocpu_options.min &&
    var.instance_ocpu_count <= local.shape_ocpu_options.max
  )

  memory_size_in_range = (
    local.shape_memory_options == null ? true :
    var.instance_memory_size_in_gbs >= local.shape_memory_options.min_in_gbs &&
    var.instance_memory_size_in_gbs <= local.shape_memory_options.max_in_gbs &&
    var.instance_memory_size_in_gbs >= var.instance_ocpu_count * local.shape_memory_options.min_per_ocpu_in_gbs &&
    var.instance_memory_size_in_gbs <= var.instance_ocpu_count * local.shape_memory_options.max_per_ocpu_in_gbs
  )

  # ---------------------------------------------------------------------------
  # Override-key validation (C10 - see the banner in configuration.tf)
  # ---------------------------------------------------------------------------
  # The service publishes is_overridable per config key, per db version. Reading
  # it is what turns "400-InvalidParameter, One or more configuration parameters
  # cannot be overridden" from an apply-time surprise into a plan-time failure
  # that names every offending key rather than one example.
  default_configurations = flatten([
    for c in data.oci_psql_default_configurations.catalogue.default_configuration_collection : c.items
  ])

  # Deterministic pick. Filtering the data source on state = ACTIVE leaves one
  # configuration per (db_version, shape family) in every case observed live -
  # db 17 has exactly one, PostgreSQL.X86-17-0_5, with 17-0_4 INACTIVE - but
  # sorting keeps the plan stable if a second ever appears.
  default_configuration_id = try(
    sort([for c in local.default_configurations : c.id])[0],
    null
  )

  default_config_catalogue = try(
    data.oci_psql_default_configuration.catalogue[0].configuration_details[0].items,
    []
  )

  config_key_is_overridable = {
    for i in local.default_config_catalogue : i.config_key => i.is_overridable
  }

  # Two distinct failure modes, two distinct messages: a key the service knows
  # and locks (shared_preload_libraries) versus a key the service has never
  # heard of (pg_stat_statements.track). Both are empty when the catalogue could
  # not be read - a lookup failure must not turn into a false accusation.
  config_override_locked_keys = length(local.default_config_catalogue) == 0 ? [] : sort([
    for k in keys(var.config_overrides) : k
    if !contains(var.config_override_extra_allowed_keys, k)
    && contains(keys(local.config_key_is_overridable), k)
    && !local.config_key_is_overridable[k]
  ])

  config_override_unknown_keys = length(local.default_config_catalogue) == 0 ? [] : sort([
    for k in keys(var.config_overrides) : k
    if !contains(var.config_override_extra_allowed_keys, k)
    && !contains(keys(local.config_key_is_overridable), k)
  ])

  # Custom engine configuration (FULL - check sheet feature 13). Only created
  # when there is something to override; otherwise the service default config
  # applies and config_id stays null.
  create_configuration = length(var.config_overrides) > 0
  configuration_id     = local.create_configuration ? oci_psql_configuration.this[0].id : var.config_id

  # ---------------------------------------------------------------------------
  # Query Insights (C11 - see the banner in main.tf)
  # ---------------------------------------------------------------------------
  # The complete OdspInsightInsightTypeEnum as of provider 9.0.0 / OCI CLI
  # 3.92.0. ONE member. It is a list rather than a scalar because the API models
  # odspInsightList as a list and Oracle can add members without a provider
  # change; when they do, the only edit here is this literal.
  query_insight_types_supported = ["QUERY_INSIGHT"]

  query_insight_types_unknown = sort(distinct([
    for i in var.query_insight_types : i.insight_type
    if !contains(local.query_insight_types_supported, i.insight_type)
  ]))

  # C14 - the complete supported set for retentionPeriodInDays. ONE member, for
  # the same reason query_insight_types_supported has one: Oracle ships exactly
  # one value and can add more without a provider change, so this is the single
  # literal to edit when they do.
  #
  # "Current supported value is 7 days. the system default is 7 days" - Go SDK
  # psql/odsp_insight.go, the CLI 3.92.0 Python SDK's OdspInsight, and the
  # provider's psql_db_system.html.markdown, all three verbatim. Oracle's Query
  # Insights documentation states the same ceiling in prose: the feature
  # "retains performance and query analysis data for a maximum of seven days".
  #
  # The half of that sentence about a SYSTEM DEFAULT is false on the create path
  # - see the C14 banner in main.tf - which is why the module now sends the
  # number rather than relying on it.
  query_insight_retention_days_supported = [7]

  # Anything a caller supplies that Oracle does not list. Null cannot appear
  # here: var.query_insight_types declares optional(number, 7), and Terraform
  # substitutes an optional() default for a null value as well as for an absent
  # one, so the null state is unreachable by construction rather than guarded.
  query_insight_retention_days_unsupported = sort(distinct([
    for i in var.query_insight_types : tostring(i.retention_period_in_days)
    if !contains(local.query_insight_retention_days_supported, i.retention_period_in_days)
  ]))

  connection = data.oci_psql_db_system_connection_detail.this

  primary_endpoint = try(local.connection.primary_db_endpoint[0], null)
  reader_endpoint  = try(local.connection.reader_endpoint[0], null)
}
