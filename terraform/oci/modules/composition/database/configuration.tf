# Engine parameter overrides, config_key -> overridden value.
#
# TLS cannot be disabled on OCI (only hostssl entries exist, ssl_min/max are
# read-only): there is no rds.force_ssl counterpart. Every connection string
# must carry sslmode=require at minimum before this unit is applied, and the
# ca_certificate output distributed for verify-ca/verify-full.
#
# Configurations are NOT replicated to a warm standby - if DR is enabled, the
# primary's overrides must be a subset of the standby's; nothing enforces it.

# The two PSQL resources consume DIFFERENT shape fields from the same service
# record: oci_psql_db_system.shape takes the PostgreSQL.-prefixed ListShapes
# `id`, while oci_psql_configuration.shape takes the un-prefixed `shape`. Both
# are read off the service rather than derived by string surgery.
data "oci_psql_shapes" "available" {
  compartment_id = var.compartment_id
}

# The service publishes is_overridable per config key per db version, so the
# catalogue turns override 400s into plan-time failures; extensions are enabled
# through the OCI-specific oci.admin_enabled_extensions key, not
# shared_preload_libraries.
data "oci_psql_default_configurations" "catalogue" {
  db_version = var.db_version
  shape      = local.configuration_shape
  state      = "ACTIVE"
}

# The list call only returns summaries; configuration_details (with the per-key
# overridability map) only comes back from the Get, so both calls are needed.
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
  # system it is attached to or the attachment is rejected. local.
  # configuration_shape IS var.shape read through the field this resource
  # accepts rather than the one the db system accepts.
  shape = local.configuration_shape

  # is_flexible and the two sizing fields move together: a flexible
  # configuration carries no sizing at all (the db system supplies it), so
  # passing var.instance_ocpu_count here would declare a FIXED configuration
  # named after a flexible shape. Both flags come from the service record.
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

  # Fails at plan with the offending keys named, instead of at apply with the
  # API's single-example message.
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
