locals {
  name_prefix = "${var.environment}-${var.project_name}-jump"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Purpose     = "JumpHost"
    }
  )

  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2023[0].id

  # Computed SSM session logging resource names
  ssm_cloudwatch_log_group_name = var.create_ssm_cloudwatch_log_group ? "${var.ssm_cloudwatch_log_group_name_prefix}-${var.environment}" : var.ssm_cloudwatch_log_group_name

  ssm_s3_bucket_name = var.create_ssm_s3_bucket ? "${var.ssm_s3_bucket_name_prefix}-${var.environment}-${data.aws_region.current.id}-${data.aws_caller_identity.current.account_id}" : var.ssm_s3_bucket_name
}
