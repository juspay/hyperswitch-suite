# Gateway NSG
# The OCI equivalent of AWS's `aws_security_group.lb_security_group`, attached
# through `oci.oraclecloud.com/oci-network-security-groups` (locals.tf).
#
# CREATED EMPTY, deliberately. It needs TWO rule groups, not one:
#   - frontend: 80 / 443 / 15021 inbound from the internet to this NSG;
#   - backend (no AWS analogue): LB subnet -> worker-node NSG on NodePorts
#     30000-32767 and kube-proxy's health port 10256. On AWS the Load Balancer
#     Controller manages the node security group's ingress for free; on OCI,
#     with the CCM held out of the VCN security lists
#     (`security-list-management-mode = "None"`), nothing does. The backend rule
#     must be authored by whoever can see BOTH this NSG and the worker-node NSG
#     that `oke` owns.
# Both rule groups go in `composition/security-rules` (the security-last phase),
# not here, to avoid splitting the posture across two modules. Hence no
# `nsg_ingress_rules` / `nsg_egress_rules` variables - do not add them.
#
# With VCN-Native Pod Networking (cni_type = "npn") pods get real VCN-routable
# IPs, so NSG rules can target pod-level mesh traffic directly - a capability
# gain over the flannel/EKS overlays where pod-to-pod traffic is invisible to
# the NSG layer.

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
