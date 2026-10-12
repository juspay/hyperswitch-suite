# =============================================================================
# Gateway NSG (check sheet feature 5, SUBSTITUTE - section 4.3)
# =============================================================================
# AWS: `aws_security_group.lb_security_group` plus caller-supplied
# `aws_security_group_rule.ingress` / `.egress`, fed to the ALB through the
# `alb.ingress.kubernetes.io/security-groups` annotation.
#
# On OCI that becomes an `oci_core_network_security_group`, attached through
# `oci.oraclecloud.com/oci-network-security-groups` (locals.tf). The
# NSG-versus-security-list question is already settled - NSGs only,
# network-security-model.md Option A - and this module is the one that document's
# scoping section named directly.
#
# THE NSG IS CREATED EMPTY, AND THAT IS A DELIBERATE DIVERGENCE FROM THIS
# MODULE'S OWN CHECK SHEET.
#
#   istio.md section 5 proposes a `network-security.tf` carrying
#   `oci_core_network_security_group_security_rule` resources for TCP 80, 443
#   and 15021 from 0.0.0.0/0, mirroring GCP's inline firewall-rule call. This
#   module does not do that. It creates the NSG object, exports its OCID, and
#   writes no rules at all - the same contract `composition/database` and
#   `composition/oci-cache-valkey` already use, and the same structure
#   network-security-model.md section 5's Phase A / Phase B split describes.
#
#   Reason: this module needs TWO rule groups, not one, and they are not
#   symmetrical.
#
#     FRONTEND, which the check sheet describes: 80 / 443 / 15021 inbound from
#     the internet to this NSG.
#
#     BACKEND, which has no AWS analogue at all: LB subnet (or this NSG) ->
#     worker-node NSG on the NodePort range 30000-32767, and -> kube-proxy's
#     health port 10256. On AWS the Load Balancer Controller auto-manages the
#     node security group's ingress for its own target groups, so this wiring is
#     free. On OCI, with
#     `oci-load-balancer-security-list-management-mode = "None"` set (locals.tf)
#     to keep the CCM out of the VCN security lists, nothing manages it - it has
#     to be hand-authored ONCE, and it must be authored by whoever can see BOTH
#     this NSG and the worker-node NSG that `oke` owns.
#
#   Putting the frontend rules here and the backend rule in `security-rules`
#   would split one security posture across two modules and two stack phases,
#   which is precisely the arrangement the security-last split exists to
#   prevent. Both groups go in `composition/security-rules`.
#
#   Consequence, so nobody looks for them: there are no `nsg_ingress_rules` /
#   `nsg_egress_rules` variables on this module. Do not add them.
#
# A REAL CAPABILITY GAIN worth recording rather than treating as neutral:
# because this stack's OKE cluster commits to VCN-Native Pod Networking
# (`cni_type = "npn"`), pods get real VCN-routable IPs in their own subnet, so
# NSG rules CAN target pod-level traffic directly. Istio's sidecar-to-sidecar
# mesh traffic is exactly that path - on flannel it would be invisible inside a
# VXLAN overlay where "you cannot use security list rules to restrict
# pod-to-pod communication", and on EKS's vpc-cni it collapses into the node's
# own groups. On OCI the mesh data plane is something the NSG layer can see and,
# if ever wanted, scope.
#
# Oracle gate: check sheet section 8 item 2, framework section 4.3 (anything
# touching the network security model is a mandatory gate item regardless of
# verdict). NOT YET CONSULTED.

resource "oci_core_network_security_group" "gateway" {
  count = var.create_gateway_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = local.nsg_display_name

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    precondition {
      condition     = var.vcn_id != null
      error_message = "vcn_id is required when create_gateway_nsg = true - an oci_core_network_security_group is created inside a VCN, unlike an AWS security group which only needs a VPC id at creation."
    }
  }
}
