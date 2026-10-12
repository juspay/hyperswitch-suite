# =============================================================================
# Engine parameter overrides (check sheet feature 13, FULL)
# =============================================================================
# Direct analogue of aws_rds_cluster_parameter_group. AWS's five
# custom_parameter_group_* variables collapse to one flat map because OCI's
# override model is flat: config_key -> overriden_config_value.
#
# This is also the mechanism for admin-enabled extensions. pgcrypto and
# uuid-ossp are available by default; pg_stat_statements, pgaudit and pglogical
# require an override here.
#
# WHAT IS NOT HERE, AND CANNOT BE (feature 14, NONE - section 4.11):
# there is no rds.force_ssl counterpart. The shared AWS catalog unit sets
# custom_parameter_group_parameters = [{ name = "rds.force_ssl", value = "0" }],
# so all seven AWS live roots currently permit plaintext PostgreSQL. On OCI that
# is impossible: only hostssl entries exist in pg_hba.conf, "non-SSL connections
# are not supported due to regulatory and compliance requirements", and
# ssl_min_protocol_version / ssl_max_protocol_version are READ-ONLY at TLSv1.2.
# A client using sslmode=disable gets "no pg_hba.conf entry for host ... no
# encryption" and fails. This module deliberately exposes no TLS off-switch,
# because building one would imply a capability that does not exist.
#
# This is the ONE app-visible break in the whole port. Every connection string
# (hyperswitch-router, superposition, decision-engine, grafana, the locker, the
# db-migration jobs) must carry sslmode=require at minimum BEFORE this unit is
# applied, and the ca_certificate output must be distributed for verify-ca or
# verify-full. Discovered at apply time it looks like a network outage, not a
# TLS problem.
#
# NOTE: configurations are NOT replicated to a warm standby. If DR is ever
# turned on, the primary's overrides must be a subset of the standby's, and
# nothing in the service enforces that.

# =============================================================================
# DIVERGENCE (C9): the two PSQL resources spell the SAME shape two DIFFERENT
# ways, and nothing in either resource's schema hints at it
# =============================================================================
# Caught by a real apply on 2026-09-04, which failed here after the NSG and the
# log group had already been created:
#
#   Error: 400-InvalidParameter, Invalid Please provide valid shape. Valid
#   Values = [VM.Standard.E6.Flex, VM.Standard.E5.Flex, VM.Standard.E4.Flex,
#   VM.Standard3.Flex]
#     with oci_psql_configuration.this[0]
#
# The ListShapes API returns TWO distinct string fields per shape and the two
# resources consume DIFFERENT ONES:
#
#   {
#     "id":    "PostgreSQL.VM.Standard.E5.Flex",   <- oci_psql_db_system.shape
#     "shape": "VM.Standard.E5.Flex",              <- oci_psql_configuration.shape
#     "is-flexible": true
#   }
#
# Verified three ways, because this module previously asserted the opposite:
#   1. Live ListShapes in ap-mumbai-1 (`oci psql shape-summary list-shapes`) -
#      every one of the 14 offered shapes carries both fields, and the distinct
#      set of `shape` values is exactly the API's own "Valid Values" list above.
#   2. Oracle's OWN provider example, examples/psql/main.tf in
#      oracle/terraform-provider-oci, sets both formats in one file:
#      `oci_psql_db_system.shape = "PostgreSQL.VM.Standard.E5.Flex"` and
#      `oci_psql_configuration.shape = "VM.Standard.E4.Flex"` /
#      `compatible_shapes = ["VM.Standard.E5.Flex", "VM.Standard.E4.Flex"]`.
#   3. Oracle's 130 default configurations in the live region: every one carries
#      an UN-prefixed `shape`.
#
# WHY THIS IS A DATA-SOURCE LOOKUP AND NOT `trimprefix(var.shape,
# "PostgreSQL.")`. Prefix-stripping is a heuristic, and it is ALREADY WRONG for
# one shape family that exists today: a multi-shape configuration's id is
# "PostgreSQL.X86 or similar" (provider docs for this resource) while its
# `shape` is the bare string "PostgreSQL" - confirmed on all 16 multi-shape
# default configurations live in ap-mumbai-1, which report
# shape = "PostgreSQL" under display names like "PostgreSQL.X86-17-0_5".
# trimprefix would produce "X86". Reading the mapping off the service means a
# future shape family that does not follow the naming convention fails loudly at
# plan time (the precondition in main.tf) instead of silently producing a shape
# string the API will reject mid-apply, which is exactly what happened here.
#
# Two separate input variables was the other rejected option: it moves the same
# error one layer up into every unit and makes a db-system/configuration shape
# MISMATCH - which is the failure this pairing exists to prevent - expressible.
data "oci_psql_shapes" "available" {
  compartment_id = var.compartment_id
}

# =============================================================================
# DIVERGENCE (C10): a third of the PostgreSQL GUCs are SYSTEM variables the API
# refuses to override, and extensions are NOT enabled via shared_preload_libraries
# =============================================================================
# Caught by the second real apply on 2026-09-04, after C9's shape fix let the
# request reach parameter validation for the first time:
#
#   Error: 400-InvalidParameter, Invalid dbConfigurationOverrides: One or more
#   configuration parameters cannot be overridden. E.g. shared_preload_libraries
#     with oci_psql_configuration.this[0]
#
# Two separate facts, both verified against the live service rather than assumed.
#
# FACT 1 - shared_preload_libraries is a system variable, and it is EMPTY.
# ListDefaultConfigurations/GetDefaultConfiguration exposes is_overridable per
# key. The active db-version-17 default configuration in ap-mumbai-1
# (PostgreSQL.X86-17-0_5) carries 345 keys, of which 118 are is_overridable =
# false. shared_preload_libraries is one of them, and its default_config_value is
# the EMPTY STRING:
#
#   { "config-key": "shared_preload_libraries", "data-type": "string",
#     "default-config-value": "", "is-overridable": false,
#     "is-restart-required": true }
#
# So the hypothesis that "pg_stat_statements is already preloaded, making the
# override redundant" is WRONG in its premise and RIGHT in its conclusion: nothing
# is preloaded by default, and the key is still unusable. Its two siblings
# session_preload_libraries and local_preload_libraries are also is_overridable =
# false, and the same holds on the db-version-16 catalogue (330 keys), so this is
# not a version quirk. Oracle's config.htm states the model directly: user
# variables "can be changed in a custom configuration list", system variables
# "can't be changed. System variables are defined according to the shape or
# requirements of the database."
#
# FACT 2 - the extension mechanism is an OCI-specific key, not a PostgreSQL one.
# .../postgresql/config-list-enable-extension.htm and .../config-list-create.htm
# both give exactly one configKey for this, verbatim:
#
#   oci psql configuration create ... --db-configuration-overrides \
#     key=oci.admin_enabled_extensions,value=<extension_name>
#
# and .../postgresql/troubleshooting.htm confirms the read side: `SHOW
# oci.admin_enabled_extensions;` is how you check whether pg_stat_statements is
# usable, and "if pg_stat_statements isn't listed, it means it's not enabled yet."
# .../postgresql/extensions.htm lists pg_stat_statements, pgaudit, pgvector,
# pg_cron and postgis under "must be enabled in configuration", against
# pgcrypto/uuid-ossp/hstore/citext under "available by default".
#
# WHAT WAS ALSO DROPPED, AND WHY - the fourth bug, caught before it fired.
# The failing overrides map carried `pg_stat_statements.track = "all"` alongside
# shared_preload_libraries, and it would have been the next 400. It is not a
# system variable; it is not a variable AT ALL. It does not appear in the 345-key
# db-17 catalogue, nor in the 330-key db-16 catalogue, nor anywhere in Oracle's
# override documentation - extension GUCs only exist once the extension is
# loaded, and the catalogue is generated from a server with no extensions loaded.
# The API named shared_preload_libraries because it was the only key it
# RECOGNISED and refused; there was no verdict at all on the one it did not
# recognise. PostgreSQL's own default for that GUC is `top`, which already
# records every top-level statement - which is all Query Insights or a
# `SELECT * FROM pg_stat_statements` needs - so `all` was buying nested-statement
# tracking nobody asked for at the price of a fourth failed apply.
#
# WHY THIS IS A PRECONDITION AND NOT A HARDCODED DENY-LIST. is_overridable is
# published per key, per db version, by the service itself. Reading it turns this
# entire class of 400 into a plan-time failure naming the offending keys - the
# same move C9 made for shapes. A hardcoded list of "bad keys" would have been
# right for shared_preload_libraries today and wrong the moment Oracle promotes a
# system variable to a user variable, or adds a version whose catalogue differs.
#
# The catalogue is necessary but NOT sufficient: oci.admin_enabled_extensions is
# itself absent from all 130 default configurations in this region while being
# the one key Oracle documents. Hence var.config_override_extra_allowed_keys,
# which is an explicit, reviewable widening rather than a silent bypass.
#
# STILL AN APPLY-TIME FACT. That Oracle documents oci.admin_enabled_extensions is
# strong evidence, not proof - it cannot be probed read-only, because the only
# way to test an override key is to create a configuration. If it too is
# rejected, the one-line retreat is `config_overrides = {}` in stack values:
# local.create_configuration goes false, no oci_psql_configuration is created at
# all, and the db system runs on the service default. That costs
# pg_stat_statements and nothing else - Query Insights (odsp_insight_details in
# main.tf) is independent of it. Oracle's query-insights.htm: enable the switch
# and "No other configuration is required." The two are complementary, not
# redundant: Query Insights is the console/metrics surface and the AWS
# Performance Insights analogue (feature 18); pg_stat_statements is in-database
# SQL access to the same underlying statistics.
data "oci_psql_default_configurations" "catalogue" {
  db_version = var.db_version
  shape      = local.configuration_shape
  state      = "ACTIVE"
}

# The list call returns summaries; configuration_details only comes back from the
# Get. Confirmed against the CLI: `default-configuration-collection
# list-default-configurations` omits configuration-details entirely, while
# `default-configuration get --default-configuration-id ...` returns all 345
# items. Chaining the two is not redundancy.
data "oci_psql_default_configuration" "catalogue" {
  count = local.default_configuration_id != null ? 1 : 0

  default_configuration_id = local.default_configuration_id
}

resource "oci_psql_configuration" "this" {
  count = local.create_configuration ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${local.display_name}-config"
  description    = "Engine parameter overrides for ${local.display_name}"
  db_version     = var.db_version

  # A configuration is bound to a shape and sizing, so it must match the db
  # system it is attached to or the attachment is rejected. `local.
  # configuration_shape` IS var.shape - the same service record, read through
  # the field this resource accepts rather than the one the db system accepts.
  # See the C9 banner above before "simplifying" this back to var.shape.
  shape = local.configuration_shape

  # is_flexible and the two sizing fields move together, and they are the second
  # half of the same finding. The provider's own argument reference for
  # instance_ocpu_count / instance_memory_size_in_gbs reads, verbatim: "Skip or
  # set it's value to 0 if configuration is for a flexible shape." Every
  # flexible default configuration live in this region carries
  # is-flexible: true with instance-ocpu-count: 0 and
  # instance-memory-size-in-gbs: 0, and Oracle's own
  # `oci_psql_configuration.test_flexible_configuration` example does the same.
  # A flexible configuration carries no sizing at all - the db system supplies
  # it - so passing var.instance_ocpu_count here would have declared a FIXED
  # configuration named after a flexible shape.
  #
  # Both values come from the service record, not from an assumption about the
  # name: the fixed variants of a flex family share the same family name and are
  # distinguished only by this bool (id PostgreSQL.VM.Standard.E5.Flex.2.32GB ->
  # shape VM.Standard.E5.Flex, is_flexible false).
  is_flexible                 = local.configuration_is_flexible
  instance_ocpu_count         = local.configuration_is_flexible ? 0 : var.instance_ocpu_count
  instance_memory_size_in_gbs = local.configuration_is_flexible ? 0 : var.instance_memory_size_in_gbs

  db_configuration_overrides {
    dynamic "items" {
      for_each = var.config_overrides
      content {
        config_key             = items.key
        overriden_config_value = items.value
      }
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # C10 guard. Fails at PLAN with the offending keys named, instead of at apply
  # with the API's "E.g. <one key>" - which reports a single example and says
  # nothing at all about keys it does not recognise.
  lifecycle {
    precondition {
      condition = length(local.config_override_locked_keys) == 0
      error_message = format(
        "config_overrides contains %d SYSTEM variable(s) that OCI Database with PostgreSQL refuses to override: %s. The db-version-%s catalogue marks these is_overridable = false. To enable an extension use oci.admin_enabled_extensions, not shared_preload_libraries.",
        length(local.config_override_locked_keys),
        join(", ", local.config_override_locked_keys),
        var.db_version,
      )
    }

    precondition {
      condition = length(local.config_override_unknown_keys) == 0
      error_message = format(
        "config_overrides contains %d key(s) that are not configuration variables of db version %s at all: %s. The service publishes %d keys for this version and none of these is among them. Extension GUCs (pg_stat_statements.track and friends) are in this class - they exist only once the extension is loaded, so they cannot be set through a configuration. If Oracle documents one of these as a valid dbConfigurationOverrides key, add it to config_override_extra_allowed_keys with the citation.",
        length(local.config_override_unknown_keys),
        var.db_version,
        join(", ", local.config_override_unknown_keys),
        length(local.default_config_catalogue),
      )
    }
  }
}
