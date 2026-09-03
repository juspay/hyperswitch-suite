locals {
  name_prefix = "${var.environment}-${var.project_name}-locker"

  gcp_sa_name = "${var.project_name}-${var.environment}-locker-sa"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "locker"
      "compliance"  = "pci-dss"
      "managed_by"  = "terraform"
    },
    var.labels
  )

  kms_key_name = var.encryption_key_name != null ? var.encryption_key_name : (
    var.create_kms_key ? module.kms[0].keys[var.kms_key_id] : null
  )

  # roles/alloydb.client alone cannot open a connection: the Auth Proxy and the
  # language connectors call the Admin API to mint an ephemeral client
  # certificate, which is authorised against the caller's own project via
  # roles/serviceusage.serviceUsageConsumer. Omitting it fails at runtime, not
  # at plan time.
  database_roles = [
    "roles/alloydb.client",
    "roles/serviceusage.serviceUsageConsumer",
  ]

  project_roles = distinct(concat(local.database_roles, var.additional_project_roles))

  # Whether ../alloydb will have produced a Secret Manager entry to grant access
  # to. Computed from configuration only, never from module.database's outputs:
  # gating a `count` on a resource attribute makes it unknown at plan time.
  # ../alloydb only writes the secret when it generated the password itself.
  secret_manager_config        = coalesce(var.database_config.secret_manager, { create = true })
  grant_master_password_access = var.create_database && var.database_config.master_password == null && local.secret_manager_config.create
}
