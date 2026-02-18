locals {
  name_prefix = "${var.environment}-${var.project_name}"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "ECR"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )

  region = var.region != null ? var.region : data.aws_region.current.region
}
