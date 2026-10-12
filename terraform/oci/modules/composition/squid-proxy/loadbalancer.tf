# =============================================================================
# Internal L4 load balancer
# =============================================================================
# OCI's Network Load Balancer is the AWS NLB counterpart: L4 only, is_private
# toggles a VCN-local IP instead of a public one, and the backend set's health
# checker supports TCP/HTTP/HTTPS/UDP/DNS. All direct structural matches for
# base/nlb + base/target-group.
#
# WHAT IT CANNOT DO, AND THIS IS THE MODULE'S ONE `NONE` VERDICT (check sheet
# feature 3): terminate TLS. oci_network_load_balancer_network_load_balancer's
# listener block exposes protocol, tcp_idle_timeout, l3ip_idle_timeout and
# udp_idle_timeout - and NO ssl_configuration block of any kind, confirmed
# against the schema. The classic oci_load_balancer_listener has one; this
# product does not. AWS's `enable_tls_listener = true` therefore has nothing to
# port to. var.tls_termination_mode forces that to be an explicit,
# per-environment decision instead of a silent capability loss, and it rejects
# the classic-LB fork outright because that fork is an unconsulted oracle-gate
# item (framework §4.1, check sheet §8 item 1).

resource "oci_network_load_balancer_network_load_balancer" "this" {
  count = var.create_nlb ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = local.display_name

  # ONE subnet, singular. OCI's NLB is regional, so there is no per-AZ subnet
  # list to supply the way an AWS NLB takes one subnet per AZ.
  subnet_id = local.nlb_subnet_id

  is_private = var.nlb_is_private

  # Unlike an AWS NLB, an OCI NLB DOES take NSGs on its front end - which is
  # why this module's health-check rule can be written as an NSG-to-NSG
  # reference rather than the AWS module's subnet-CIDR workaround. See
  # network.tf for the part that is still unconfirmed.
  network_security_group_ids = local.nlb_nsg_ids

  # NOT var.nlb_preserve_source_destination - see that variable's neighbour
  # nlb_transparent_mode for why the two were split (C24). This is OCI's
  # deeper bump-in-the-wire mode and needs skip_source_dest_check on the
  # backend VNICs, which nothing in this module sets.
  is_preserve_source_destination = var.nlb_transparent_mode

  dynamic "reserved_ips" {
    for_each = var.nlb_reserved_ip_id != null ? [var.nlb_reserved_ip_id] : []

    content {
      id = reserved_ips.value
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_network_load_balancer_backend_set" "this" {
  count = var.create_nlb ? 1 : 0

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.this[0].id
  name                     = local.backend_set_name
  policy                   = var.backend_set_policy

  # Backends are NOT declared here - oci_core_instance_pool.load_balancers
  # registers them as the pool scales. See the open question on that block in
  # compute.tf, which is specifically about whether that works for an NLB.
  #
  # This is the correct home for "Squid's access log shows the real client
  # IP" (C24): OCI does the readdressing at the backend-set level without
  # requiring skip_source_dest_check on the backend VNIC, unlike the NLB's own
  # is_preserve_source_destination above.
  is_preserve_source = var.nlb_preserve_source_destination

  health_checker {
    protocol            = var.health_check.protocol
    port                = local.health_check_port
    url_path            = var.health_check.url_path
    return_code         = var.health_check.return_code
    interval_in_millis  = var.health_check.interval_in_millis
    timeout_in_millis   = var.health_check.timeout_in_millis
    retries             = var.health_check.retries
    response_body_regex = var.health_check.response_body_regex
  }
}

resource "oci_network_load_balancer_listener" "this" {
  count = var.create_nlb ? 1 : 0

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.this[0].id
  name                     = "${local.name_prefix}-tcp"
  default_backend_set_name = oci_network_load_balancer_backend_set.this[0].name
  port                     = var.squid_port

  # TCP, and there is no alternative that terminates TLS. A listener with
  # protocol = "TLS" does not exist on this product; see the file header.
  protocol = "TCP"

  # Squid CONNECT tunnels to slow payment processors are long-lived; the
  # default idle timeout tears them down mid-transaction.
  tcp_idle_timeout = var.tcp_idle_timeout
}
