# =============================================================================
# Engine parameter overrides for the card vault's database
# =============================================================================
# Direct analogue of the AWS locker's
# database_config.create_custom_parameter_group /
# custom_parameter_group_parameters pair, which nests
# aws_rds_cluster_parameter_group. OCI's override model is flat -
# config_key -> overriden_config_value - so the AWS module's five
# custom_parameter_group_* variables collapse to one map.
#
# WHAT IS NOT HERE, AND CANNOT BE (check sheet feature 18, verdict NONE):
# there is no rds.force_ssl counterpart. The live AWS catalog unit for the
# LOCKER sets custom_parameter_group_parameters = [{ name = "rds.force_ssl",
# value = "0" }] on the card vault's own database - i.e. the platform's most
# security-sensitive database currently permits plaintext PostgreSQL, for
# reasons not documented anywhere in the AWS module tree. On OCI that is
# impossible: pg_hba.conf carries only `hostssl` entries, non-SSL connections
# are rejected unconditionally, and ssl_min/max_protocol_version are read-only.
#
# This is the one NONE verdict in the whole locker port that is an IMPROVEMENT
# (check sheet section 4.6 and the "Encryption in transit" row of section 10,
# verdict Stronger). Do not attempt to "match" AWS's current permissiveness -
# there is no lever, and pulling one would be a regression.
#
# The operational consequence is real and must be handled BEFORE first apply:
# the card-vault application's connection string needs sslmode=require at
# minimum, and the module's `db_ca_certificate` output distributed for
# verify-ca/verify-full. Discovered at apply time this looks like a network
# outage, not a TLS problem.
#
# NOTE: configurations are NOT replicated to a warm standby. If DR is ever
# turned on, the primary's overrides must be a subset of the standby's, and
# nothing in the service enforces that.

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
