locals {
  name_prefix = "${var.project_name}-${var.environment}-oke"

  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "node-pool-security"
      managed_by  = "terraform"
    },
    var.freeform_tags
  )
}
