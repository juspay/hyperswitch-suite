locals {
  name_prefix  = "${var.environment}-${var.project_name}-bastion"
  display_name = local.name_prefix

  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "bastion-host"
      managed_by  = "terraform"
    },
    var.freeform_tags
  )

  availability_domain = coalesce(
    var.availability_domain,
    data.oci_identity_availability_domains.this.availability_domains[0].name
  )

  namespace = data.oci_objectstorage_namespace.this.namespace

  bastion_target_subnet_id = coalesce(var.bastion_target_subnet_id, var.subnet_id)

  # NSG membership is declared on the CONSUMER (create_vnic_details.nsg_ids).
  # This module's NSG is the one NSG in the port that cannot stay zero-ingress.
  own_nsg_ids = var.create_nsg ? [oci_core_network_security_group.this[0].id] : []
  nsg_ids     = concat(local.own_nsg_ids, var.additional_nsg_ids)

  session_log_bucket_name = coalesce(var.session_log_bucket_name, "${local.name_prefix}-session-logs")

  user_data = coalesce(
    var.user_data,
    templatefile("${path.module}/templates/userdata.sh", {
      hostname = local.display_name
    })
  )

  instance_metadata = merge(
    var.metadata,
    length(var.ssh_public_keys) > 0 ? { ssh_authorized_keys = join("\n", var.ssh_public_keys) } : {},
    { user_data = base64encode(local.user_data) }
  )

  bastion_id = var.create_bastion ? try(oci_bastion_bastion.this[0].id, null) : null

  # Source of the one required inbound rule on the target; null when not owned here.
  bastion_private_endpoint_ip = var.create_bastion ? try(oci_bastion_bastion.this[0].private_endpoint_ip_address, null) : null

  # Reports what was CONFIGURED, not live state - no Terraform resource for OCI Run Command.
  migration_mode_status = var.enable_migration_mode ? "ENABLED - grant the Run Command policy verb to this host's dynamic group, then REVOKE it when the migration is done. Nothing in terraform plan will remind you." : "DISABLED"

  connection_guide = templatefile("${path.module}/templates/connection_guide.tftpl", {
    region              = var.region
    instance_name       = local.display_name
    instance_id         = oci_core_instance.this.id
    instance_private_ip = oci_core_instance.this.private_ip
    bastion_id          = coalesce(local.bastion_id, "<no bastion created by this module - supply the shared bastion OCID>")
    bastion_endpoint_ip = coalesce(local.bastion_private_endpoint_ip, "<unknown>")
    session_ttl         = var.bastion_max_session_ttl_seconds
    connection_targets  = var.connection_targets
    session_recording   = var.enable_session_recording
    migration_mode      = local.migration_mode_status
  })
}
