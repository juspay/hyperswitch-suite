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

  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2[0].id

  userdata_external = templatefile("${path.module}/templates/userdata.sh", {
    jump_type         = "external"
    environment       = var.environment
    cloudwatch_region = data.aws_region.current.name
  })

  userdata_internal = templatefile("${path.module}/templates/userdata.sh", {
    jump_type         = "internal"
    environment       = var.environment
    cloudwatch_region = data.aws_region.current.name
  })
}
