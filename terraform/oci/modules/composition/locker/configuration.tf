# Engine parameter overrides for the card vault's database, config_key ->
# overridden value.
#
# TLS cannot be disabled on OCI (pg_hba.conf carries only hostssl entries), so
# there is no rds.force_ssl counterpart - the one NONE verdict in this port that
# is an IMPROVEMENT over AWS, whose live locker allows plaintext. Every card-vault
# connection string needs sslmode=require at minimum, plus the db_ca_certificate
# output for verify-ca/verify-full, BEFORE first apply.
#
# Configurations are NOT replicated to a warm standby - if DR is enabled, the
# primary's overrides must be a subset of the standby's; nothing enforces it.

resource "oci_psql_configuration" "locker" {
  count = local.create_db_configuration ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${local.db_display_name}-config"
  description    = "Engine parameter overrides for ${local.db_display_name}"
  db_version     = var.database_config.db_version

  # A configuration is bound to a shape and sizing, so it must match the db
  # system it attaches to or the attachment is rejected.
  shape                       = var.database_config.shape
  instance_ocpu_count         = var.database_config.instance_ocpu_count
  instance_memory_size_in_gbs = var.database_config.instance_memory_size_in_gbs

  db_configuration_overrides {
    dynamic "items" {
      for_each = var.database_config.config_overrides
      content {
        config_key             = items.key
        overriden_config_value = items.value
      }
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
