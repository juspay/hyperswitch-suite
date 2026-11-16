locals {
  name_prefix  = "${var.environment}-${var.project_name}-squid-audit"
  display_name = local.name_prefix

  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "squid-audit-instance"
      managed_by  = "terraform"
      purpose     = "security-team-audit"
    },
    var.freeform_tags
  )

  availability_domain = coalesce(
    var.availability_domain,
    data.oci_identity_availability_domains.this.availability_domains[0].name
  )

  # NSG membership is declared on the CONSUMER (create_vnic_details.nsg_ids),
  # not on the NSG. This module's NSG carries the SSH-from-VPN rules inline.
  own_nsg_ids = var.create_nsg ? [oci_core_network_security_group.this[0].id] : []
  nsg_ids     = concat(local.own_nsg_ids, var.additional_nsg_ids)

  # cloud-init user-data that creates the non-root review user (secreview-style:
  # sudo, SSH-key-only), hardens sshd, and opens ufw tcp:22 to exactly the VPN
  # source ranges.
  review_user = "secreview"

  user_data = templatefile("${path.module}/templates/userdata.sh", {
    hostname         = local.display_name
    review_user      = local.review_user
    ssh_public_key   = var.ssh_public_key
    vpn_source_cidrs = join(" ", var.vpn_source_cidrs)
  })

  instance_metadata = merge(
    var.metadata,
    { user_data = base64encode(local.user_data) }
  )
}