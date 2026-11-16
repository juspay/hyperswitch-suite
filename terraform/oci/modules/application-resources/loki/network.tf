# =============================================================================
# Ingress boundary for the query path (check sheet feature 6, FULL)
# =============================================================================
# AWS builds FOUR security objects here:
#   aws_security_group.this               - the ALB's own SG
#   aws_security_group_rule.ingress/egress - caller-supplied rules on it
#   aws_security_group_rule.lb_egress_to_eks       - module-authored, port 8080
#   aws_security_group_rule.eks_ingress_from_loki  - module-authored, and
#     written onto the EXTERNALLY-OWNED EKS node security group, passed in as
#     `var.eks_node_security_group_id`
#
# ON OCI THIS MODULE BUILDS EXACTLY ONE OBJECT, AND IT IS EMPTY.
#
# The NSG-vs-security-list question is already settled: NSGs only
# (network-security-model.md Option A). What changes here is WHO WRITES THE
# RULES, and that is the divergence worth recording at the point of divergence.
#
# AWS treats a rule as a first-class resource separate from the group, so a
# state that does not own the group can still write into it - which is how
# `eks_ingress_from_loki` works. The platform's own answer to that on AWS is
# `composition/security-rules`: a LAST-PHASE module that owns every cross-module
# rule precisely so the app modules do not have to depend on each other's
# security objects. network-security-model.md section 5 carries that structure
# forward onto OCI unchanged, and this port applies it: the module owns the NSG
# object and exports its OCID, and `composition/security-rules` writes both the
# frontend ingress rules AND the LB-to-node-pool rule in the security-last
# phase.
#
# CONSEQUENCES, so nobody looks for the missing pieces:
#   * `eks_node_security_group_id` disappears from this module's inputs
#     entirely, unlike AWS where it is a required companion whenever
#     `create_security_group = true`.
#   * There are no `nsg_ingress_rules` / `nsg_egress_rules` variables. Adding
#     them would put half the rule set here and half in `security-rules`, which
#     is the arrangement the split exists to prevent. Do not add them "to
#     simplify"; that reintroduces the dependency cycle.
#   * This is a STRATEGY difference, not a capability loss - hence feature 6 is
#     FULL, not PARTIAL.
#
# Same contract as `composition/database`'s and `composition/oci-cache-valkey`'s
# module-owned NSGs. Oracle gate item (check sheet section 8 item 2, framework
# section 4.3 - anything touching the network security model): NOT YET
# CONSULTED.
#
# OPEN, and it decides whether this object is needed at all: does an OCI Load
# Balancer actually front Loki's query path, or does ingress arrive through the
# Istio mesh? The AWS module's `-alb-sg` naming and its 8080 LB-to-pod rule
# assume a dedicated load balancer. If OCI routes the query path through the
# mesh ingress instead, this NSG folds into whatever NSG the gateway already
# owns. Check sheet section 9 Q2.

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
