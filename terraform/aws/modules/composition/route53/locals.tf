locals {
  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      Component   = "Route53 Module"
      ManagedBy   = "terraform"
    }
  )
}
