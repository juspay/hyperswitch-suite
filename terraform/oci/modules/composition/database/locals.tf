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

  # is_regionally_durable selects between the service's two data placement
  # models: true puts nodes in different availability domains, false in
  # different fault domains of the same AD. In a single-AD region only false +
  # an explicit AD is expressible (the API 400s on true), and both models land
  # the nodes in the same three fault domains anyway.
  availability_domain_names = [
    for ad in data.oci_identity_availability_domains.this.availability_domains : ad.name
  ]

  availability_domain_count = length(local.availability_domain_names)

  # Explicit override wins; otherwise index 0, which in a single-AD region is
  # the only entry. Null when regionally durable, because the provider forbids
  # the pair in that direction.
  availability_domain = (
    var.is_regionally_durable ? null :
    var.availability_domain != null ? var.availability_domain :
    try(local.availability_domain_names[0], null)
  )

  # Cross-region DR is via Replication with Warm Standby, off by default.
  is_standby = var.enable_warm_standby

  # Restore and warm standby are mutually exclusive on the same db system.
  # Exactly one source block may be emitted; outputs.tf rejects a combination.
  source_kind = (
    local.is_standby ? "DB_SYSTEM" : (
      var.source_backup_id != null ? "BACKUP" : (
        var.source_pitr != null ? "POINT_IN_TIME_DB_SYSTEM" : null
      )
    )
  )

  # OCI has no manage_master_user_password, so the module generates the password
  # itself and optionally writes it to OCI Vault.
  generate_password = !local.is_standby && var.admin_password == null
  admin_password    = local.is_standby ? null : (local.generate_password ? random_password.admin[0].result : var.admin_password)

  vault_secret_create = var.vault_secret != null ? (var.vault_secret.create && !local.is_standby) : false
  vault_secret_name   = local.vault_secret_create ? coalesce(var.vault_secret.secret_name, "${local.display_name}-admin-password") : null

  # VAULT_SECRET when the module owns a Vault secret, PLAIN_TEXT otherwise.
  # PLAIN_TEXT still never carries a literal - the value is either generated
  # here or handed in by the caller from its own secret store.
  password_type = local.vault_secret_create ? "VAULT_SECRET" : "PLAIN_TEXT"

  # The module owns the empty NSG and exports its OCID; the rules are written
  # by the security-last phase unit.
  nsg_ids = compact(concat(
    var.create_nsg ? [oci_core_network_security_group.this[0].id] : [],
    var.nsg_ids
  ))

  # var.shape is the ListShapes `id` (the PostgreSQL.-prefixed string that
  # oci_psql_db_system.shape takes); oci_psql_configuration.shape takes the
  # same record's un-prefixed `shape`. Both are read off the service rather
  # than derived by string surgery, because the prefix is a naming convention
  # and not a contract.
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

  # Sizing bounds are a property of THIS REGION's shape catalogue, not of the
  # provider schema - so a bad size is caught at plan, not minutes into a
  # create. Both option lists are empty on fixed-size shape ids, where sizing
  # is baked into the id, so the try() yields null and the guards no-op.
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

  # The service publishes is_overridable per config key per db version. Reading
  # it turns override 400s into plan-time failures that name every offending
  # key rather than one example.
  default_configurations = flatten([
    for c in data.oci_psql_default_configurations.catalogue.default_configuration_collection : c.items
  ])

  # Deterministic pick. Filtering the data source on state = ACTIVE leaves one
  # configuration per (db_version, shape family) in every case observed live,
  # but sorting keeps the plan stable if a second ever appears.
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
  # and locks (shared_preload_libraries) versus a key it has never heard of. A
  # lookup failure must not turn into a false accusation.
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

  # Even when empty config_overrides, config_id may point at a pre-existing
  # configuration.
  create_configuration = length(var.config_overrides) > 0
  configuration_id     = local.create_configuration ? oci_psql_configuration.this[0].id : var.config_id

  # Query Insights. The enum has exactly ONE member and is a list because the
  # API models odspInsightList as a list.
  query_insight_types_supported = ["QUERY_INSIGHT"]

  query_insight_types_unknown = sort(distinct([
    for i in var.query_insight_types : i.insight_type
    if !contains(local.query_insight_types_supported, i.insight_type)
  ]))

  # The complete supported set for retentionPeriodInDays. ONE member; Oracle can
  # add more without a provider change, so this is the single literal to edit.
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
