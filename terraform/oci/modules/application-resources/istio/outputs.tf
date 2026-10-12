# =============================================================================
# Output contract - the AWS module's 4 outputs, plus what OCI needs and AWS
# did not.
# =============================================================================

output "policy_statements" {
  description = <<-EOT
    ALWAYS EMPTY, BY DESIGN. Present so every application module in this port
    presents the same identity contract and the stack can concatenate them all
    without special-casing this one.

    Istio needs no cloud identity: identity-model.md section 1.2 row 13 records
    it as "no" pod identity, "helm only", and nothing in the OCI port changes
    that - the gateway's exposure runs through the built-in Cloud Controller
    Manager, which needs no IAM role and no ServiceAccount.

    If this list is ever non-empty, something has been added to this module that
    does not belong in it.
  EOT
  value       = []
}

output "gateway_nsg_id" {
  description = <<-EOT
    OCID of the module-owned, DELIBERATELY EMPTY Network Security Group attached
    to the gateway's load balancer. Replaces AWS's `lb_security_group_id`.

    THE CONSUMED OUTPUT, and it carries two rule groups rather than one.
    `composition/security-rules`, in the security-last phase, writes:
      * frontend: TCP 80 / 443 / 15021 inbound from the internet to this NSG;
      * backend:  this NSG (or the LB subnet) -> the worker-node NSG on the
        NodePort range 30000-32767 and on kube-proxy's health port 10256.

    The backend group has NO AWS ANALOGUE - the AWS Load Balancer Controller
    manages the node security group's ingress automatically. On OCI, with the
    CCM held out of the VCN security lists
    (`oci-load-balancer-security-list-management-mode = "None"`), nothing does.
    Omitting it fails CLOSED: the load balancer cannot reach any node.
  EOT
  value       = one(oci_core_network_security_group.gateway[*].id)
}

output "gateway_nsg_ids" {
  description = "Every NSG attached to the gateway's load balancer - the module-owned one plus any passed in. Note OCI's hard cap of 5 NSGs per VNIC."
  value       = local.gateway_nsg_ids
}

output "gateway_reserved_ip" {
  description = <<-EOT
    The reserved public IP address the gateway's load balancer is pinned to, or
    null. WHAT DNS SHOULD POINT AN A RECORD AT.

    New relative to AWS, and the shape of the DNS wiring changes with it: AWS
    aliased a Route 53 record to the ALB's own persistent hostname, so there was
    no address to output. Consistent with route53.md's and load-balancer.md's
    own Reserved-Public-IP findings.
  EOT
  value       = one(oci_core_public_ip.gateway[*].ip_address)
}

output "gateway_reserved_ip_id" {
  description = "OCID of the reserved public IP - the value rendered into the `oci.oraclecloud.com/reserved-ips` annotation."
  value       = one(oci_core_public_ip.gateway[*].id)
}

output "gateway_service_annotations" {
  description = <<-EOT
    The full CCM annotation map rendered onto the gateway Service. Surfaced for
    plan review, because three of these are load-bearing and easy to lose:
    `load-balancer-type`, `oci-network-security-groups`, and
    `security-list-management-mode = "None"` - the last of which is what keeps
    the CCM from silently creating VCN security-list rules that
    network-security-model.md says should not exist.
  EOT
  value       = local.ccm_annotations
}

output "load_balancer_type" {
  description = "`lb` (L7, mirroring AWS's ALB) or `nlb` (L4, mirroring GCP's passthrough NLB). The unresolved TLS-termination fork - check sheet section 9 Q2."
  value       = var.load_balancer_type
}

output "helm_releases_created" {
  description = "Whether this module installed the three Helm releases, or left them to ArgoCD. False on every AWS live root reviewed."
  value       = var.create_helm_releases
}

output "istio_namespace" {
  description = "Namespace the Istio components install into."
  value       = var.istio_namespace
}

output "cluster_id" {
  description = "OCID of the OKE cluster Istio is installed on. Replaces the AWS module's `cluster_name` output; OCI addresses the cluster by OCID."
  value       = var.cluster_id
}

output "host_domains_map" {
  description = "Passthrough of var.host_domains. Unchanged from both AWS and GCP - no cloud resource behind it on any cloud."
  value       = var.host_domains
}

output "region" {
  description = "Region, echoed from the input. Unchanged from AWS."
  value       = var.region
}
