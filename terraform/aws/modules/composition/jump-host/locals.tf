locals {
  external_name_prefix = "${var.environment}-${var.project_name}-external-jump"
  internal_name_prefix = "${var.environment}-${var.project_name}-internal-jump"

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
  internal_ami_id = var.internal_jump_ami_id != null ? var.internal_jump_ami_id : data.aws_ami.amazon_linux_2023[0].id

  userdata_internal = templatefile("${path.module}/templates/userdata.sh", {
    jump_type         = "internal"
    environment       = var.environment
    cloudwatch_region = data.aws_region.current.id
    internal_jump_ip  = ""  # Not used for internal jump
    os_username       = "ec2-user"
  })
}
