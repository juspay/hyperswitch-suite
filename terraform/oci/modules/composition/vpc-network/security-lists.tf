# Dedicated management / OCI Bastion security list.
#
# The management subnet hosts the OCI Bastion service's private endpoint VNIC,
# a SERVICE VNIC. The Bastion service does not support NSGs, so its data-plane
# egress is governed ONLY by this subnet's SECURITY LIST, never by an NSG. The
# stock default list that subnets.tf attaches everywhere else is deliberately
# EMPTIED (vcn.tf) because security-list rules UNION with NSG rules - a
# populated default would silently widen every NSG.
#
# This is the single, named, LEGITIMATE non-default security list - the exact
# case the security-rules guard names. Scope: security lists apply per-subnet,
# so the jump-host instance VNIC in the same subnet gains these egress paths
# too (acceptable, actually required if operators SSH into the jump host). No
# ingress on this list.

resource "oci_core_security_list" "management_bastion" {
  count          = can(local.named_subnets.management.cidr) ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_prefix}-management-bastion"

  # Stateful (default). Each egress opens one of the three SSH-forwarded data
  # paths to its target; return traffic is covered by stateful tracking, and the
  # targets' own NSG ingress rules permit the target side. No ingress here.
  egress_security_rules {
    description = "OCI Bastion service: SSH to jump host (TCP 22)"
    destination = local.named_subnets.management.cidr
    protocol    = "6"
    stateless   = false
    tcp_options {
      min = 22
      max = 22
    }
  }

  egress_security_rules {
    description = "OCI Bastion service: kubectl to OKE Kubernetes API endpoint (TCP 6443)"
    destination = local.cp_subnet_cidr_for_bastion
    protocol    = "6"
    stateless   = false
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  egress_security_rules {
    description = "OCI Bastion service: psql to PostgreSQL (TCP 5432)"
    destination = local.named_subnets.database.cidr
    protocol    = "6"
    stateless   = false
    tcp_options {
      min = 5432
      max = 5432
    }
  }

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}