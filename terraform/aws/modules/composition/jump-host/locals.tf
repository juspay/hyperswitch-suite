locals {
  external_name_prefix = "${var.environment}-${var.project_name}-external-jump"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Purpose     = "JumpHost"
    }
  )

  external_ami_id = var.external_jump_ami_id != null ? var.external_jump_ami_id : data.aws_ami.amazon_linux_2023[0].id
}
