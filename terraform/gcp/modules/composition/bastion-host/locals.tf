locals {
  name_prefix = "${var.environment}-${var.project_name}-bastion"

  # Named here rather than inlined at the single use site because the
  # tunnel_commands output has to reproduce the exact same instance name in
  # the gcloud command it emits - two independent "${local.name_prefix}-vm"
  # string builds would be a silent drift waiting to happen.
  instance_name = "${local.name_prefix}-vm"

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
