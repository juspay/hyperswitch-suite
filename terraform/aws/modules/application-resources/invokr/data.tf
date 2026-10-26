data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_kms_key" "existing" {
  count = !var.kms.create && var.kms.key_arn != null ? 1 : 0

  key_id = var.kms.key_arn
}

data "aws_secretsmanager_secret" "existing_application" {
  count = !var.create_application_secret && var.existing_application_secret_arn != null ? 1 : 0

  arn = var.existing_application_secret_arn
}
