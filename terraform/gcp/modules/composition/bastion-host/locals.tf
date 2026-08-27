locals {
  name_prefix = "${var.environment}-${var.project_name}-bastion"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "bastion-host"
      "managed_by"  = "terraform"
    },
    var.labels
  )
}
