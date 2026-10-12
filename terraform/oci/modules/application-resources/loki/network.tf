# Ingress boundary for the query path
# ON OCI THIS MODULE BUILDS EXACTLY ONE OBJECT, AND IT IS EMPTY. AWS builds four
# security objects here (one a rule on an externally-owned node SG); on OCI the
# module owns the NSG object and exports its OCID, and `composition/security-rules`
# - the security-last-phase module that owns every cross-module rule - writes
# both the frontend ingress rules AND the LB-to-node-pool rule there. That is
# why `eks_node_security_group_id` is absent and why there are no
# `nsg_ingress_rules`/`nsg_egress_rules` variables. A strategy difference, not a
# capability loss.
#
# OPEN: does an OCI Load Balancer actually front Loki's query path, or does
# ingress arrive through the Istio mesh? If the latter, this NSG folds into the
# gateway's NSG and `create_nsg` should be false.

resource "oci_core_network_security_group" "this" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = local.nsg_display_name

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    precondition {
      condition     = var.vcn_id != null
      error_message = "vcn_id is required when create_nsg = true - an oci_core_network_security_group is created inside a VCN, unlike an AWS security group which only needs a VPC id."
    }
  }
}
