locals {
  display_name     = coalesce(var.display_name, "${var.project_name}-${var.environment}-eso-vault")
  key_display_name = coalesce(var.key_display_name, "${var.project_name}-${var.environment}-eso-key")

  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "vault"
      managed_by  = "terraform"
    },
    var.region != null ? { region = var.region } : {},
    var.freeform_tags
  )
}