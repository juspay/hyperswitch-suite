###############################################################################
# Dedicated management / OCI Bastion security list
#
# The management subnet hosts the OCI Bastion service's private endpoint VNIC
# (10.90.1.231 in this env). That VNIC is a SERVICE VNIC - the Bastion service
# does not support NSGs (docs.oracle.com .../networksecuritygroups.htm), so its
# data-plane egress is governed ONLY by the management subnet's SECURITY LIST,
# never by an NSG. The stock VCN default list - which subnets.tf attaches
# everywhere - is deliberately EMPTIED (vcn.tf) because security-list rules
# UNION with NSG rules (allow if ANY rule allows), so a populated default
# would silently widen every NSG.
#
# This dedicated list is the single, named exception to the NSG-only model
# (network-security-model.md section 5.1). It exists ONLY because the OCI
# Bastion service is a resource type with a VNIC but no NSG support - precisely
# the case the security-rules `check "no_non_default_security_lists"` guard
# names as the legitimate one. composition/security-rules is updated to assert
# this is the ONLY non-default list carrying exactly these rules.
#
# SCOPE: security lists apply per-subnet, so the jump-host instance VNIC
# (10.90.1.3) in the same subnet also gains these egress paths - acceptable and
# actually REQUIRED if operators SSH into the jump host and run kubectl/psql
# from inside it. Destinations are scoped to the exact target subnets. There is
# NO ingress on this list.
###############################################################################

resource "oci_core_security_list" "management_bastion" {
  count          = can(local.named_subnets.management.cidr) ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_prefix}-management-bastion"

  # Stateful (default). Each egress allows the OCI Bastion service's data-plane
  # VNIC to open the three SSH-forwarded data paths to its targets. Return
  # traffic is covered by stateful tracking; the targets' own NSG ingress rules
  # (written by composition/security-rules from the bastion private endpoint IP)
  # permit the target side. No ingress rules on this list.
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