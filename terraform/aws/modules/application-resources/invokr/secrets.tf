resource "aws_secretsmanager_secret" "application" {
  count = var.create_application_secret ? 1 : 0

  name        = var.application_secret_name
  description = coalesce(var.application_secret_description, "Optional KMS-encrypted bootstrap configuration for ${local.name_prefix}")
  kms_key_id = (
    var.application_secret_kms_key_id != null
    ? var.application_secret_kms_key_id
    : local.kms_key_arn
  )
  recovery_window_in_days = var.application_secret_recovery_window_in_days

  tags = merge(local.common_tags, var.application_secret_tags)

  depends_on = [terraform_data.application_secret_validation]
}
