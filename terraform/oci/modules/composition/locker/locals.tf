locals {
  # Matches the AWS module's local.name_prefix exactly
  # ("${var.environment}-${var.project_name}-locker"), so resource names are
  # recognisable across clouds during the migration window.
  name_prefix = "${var.environment}-${var.project_name}-locker"

  # OCI has two tag namespaces where AWS has one. freeform_tags is the tags_all
  # analogue; defined_tags is passed through untouched because it needs a tag
  # namespace this module does not own.
  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "locker"
      pci_scope   = "cardholder-data"
      managed_by  = "terraform"
    },
    var.tags
  )

  # ---------------------------------------------------------------------------
  # Key custody (check sheet feature 14, FULL)
  # ---------------------------------------------------------------------------
  # AWS nests terraform-aws-modules/kms/aws and can either create a key or
  # accept one. Same two paths here, but OCI needs a two-level object: a key
  # lives inside a VAULT, and every crypto call goes to that vault's
  # management/crypto endpoint. So "create a KMS key" becomes "create a vault
  # and a key in it", and `vault_id` has no AWS counterpart at all.
  create_vault = var.vault.create
  vault_id     = local.create_vault ? oci_kms_vault.locker[0].id : var.vault.vault_id

  management_endpoint = (
    local.create_vault
    ? oci_kms_vault.locker[0].management_endpoint
    : var.vault.management_endpoint
  )

  create_key = var.kms_key.create
  key_id     = local.create_key ? oci_kms_key.locker[0].id : var.kms_key.key_id

  # AWS's kms_key_arns output is `concat(created, var.kms.key_arns)`. Same
  # shape, OCIDs instead of ARNs.
  key_ids = compact(concat(
    local.create_key ? [oci_kms_key.locker[0].id] : [],
    var.kms_key.additional_key_ids
  ))

  # ---------------------------------------------------------------------------
  # Database credential (check sheet feature 15's credential half)
  # ---------------------------------------------------------------------------
  # Either this module owns a Vault secret whose content OCI generates, or the
  # caller supplies a secret it already owns. There is deliberately NO third
  # path taking a literal password: no code path in this module can put a
  # credential into Terraform state. See secrets.tf.
  create_db_secret = var.create_database && var.db_admin_secret.create

  db_secret_id = (
    local.create_db_secret
    ? oci_vault_secret.db_admin_password[0].id
    : var.db_admin_secret.secret_id
  )

  db_secret_version = (
    local.create_db_secret
    ? oci_vault_secret.db_admin_password[0].current_version_number
    : var.db_admin_secret.secret_version
  )

  db_secret_name = coalesce(var.db_admin_secret.secret_name, "${local.name_prefix}-db-admin-password")

  # ---------------------------------------------------------------------------
  # Database placement and shape
  # ---------------------------------------------------------------------------
  db_display_name = coalesce(var.database_config.display_name, "${local.name_prefix}-pgsql")

  # The module-owned, deliberately EMPTY NSG. Mirrors composition/database's
  # network.tf: this module owns the object, composition/security-rules (last
  # stack phase) writes the rules into it. See network.tf.
  db_nsg_ids = compact(concat(
    var.create_nsg && var.create_database ? [oci_core_network_security_group.locker_database[0].id] : [],
    var.database_config.additional_nsg_ids
  ))

  create_db_configuration = var.create_database && length(var.database_config.config_overrides) > 0

  db_configuration_id = (
    local.create_db_configuration
    ? oci_psql_configuration.locker[0].id
    : var.database_config.config_id
  )

  # Warm standby (check sheet feature 16, SUBSTITUTE). Off by default; see the
  # long note in database.tf before turning it on.
  is_standby = var.create_database && var.database_config.enable_warm_standby

  connection = var.create_database ? data.oci_psql_db_system_connection_detail.locker[0] : null

  primary_endpoint = try(local.connection.primary_db_endpoint[0], null)
  reader_endpoint  = try(local.connection.reader_endpoint[0], null)

  enable_db_logs = var.create_database && var.enable_service_logs
}
