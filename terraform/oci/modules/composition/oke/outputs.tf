# =============================================================================
# oke - outputs
# =============================================================================
# The outputs are the contract. Where the semantics survive the port the AWS
# name is kept; where they do not, the name changes so nobody reads an OCID as
# an ARN. Mapping table is in eks.md section 5.
# =============================================================================

# -----------------------------------------------------------------------------
# Cluster identity - consumed by oke-kubernetes-resources (phase 2) and by every
# workload-identity policy statement (identity-model.md: the cluster OCID is one
# of the four `where` conditions that ARE the security boundary).
# -----------------------------------------------------------------------------

output "cluster_id" {
  description = "OCID of the OKE cluster. Replaces AWS `cluster_id`, and also stands in for `cluster_arn` - OCI has OCIDs, not ARNs, so there is no separate ARN output."
  value       = module.oke.cluster_id
}

output "cluster_name" {
  description = "Name of the OKE cluster."
  value       = local.cluster_name
}

output "cluster_type" {
  description = "OKE cluster tier. 'enhanced' is the prerequisite for OKE Workload Identity; oke-workload-identity should assert on this."
  value       = lower(var.cluster_type)
}

# RENAMED from AWS `cluster_endpoint` (singular). OKE exposes several endpoint
# addresses at once (private_endpoint, public_endpoint, vcn_hostname_endpoint),
# so the plural map is the honest shape.
output "cluster_endpoints" {
  description = "Map of OKE cluster endpoints (private_endpoint, public_endpoint, ...). Replaces AWS `cluster_endpoint`, which was singular."
  value       = module.oke.cluster_endpoints
}

output "cluster_endpoint" {
  description = "The single endpoint a Kubernetes provider should target: the public endpoint if the control plane is public, otherwise the private one. Convenience projection of cluster_endpoints for oke-kubernetes-resources."
  value = format("https://%s", (
    var.control_plane_is_public && var.assign_public_ip_to_control_plane
    ? lookup(module.oke.cluster_endpoints, "public_endpoint", "")
    : lookup(module.oke.cluster_endpoints, "private_endpoint", "")
  ))
}

# RENAMED from AWS `cluster_certificate_authority_data`.
output "cluster_ca_cert" {
  description = "Base64-encoded cluster CA certificate. Replaces AWS `cluster_certificate_authority_data`. Required by oke-kubernetes-resources to configure its kubernetes/helm providers."
  value       = module.oke.cluster_ca_cert
  sensitive   = true
}

output "cluster_kubeconfig" {
  description = "Decoded kubeconfig for the cluster."
  value       = module.oke.cluster_kubeconfig
  sensitive   = true
}

output "kubernetes_version" {
  description = "Kubernetes version the control plane was created with."
  value       = var.kubernetes_version
}

# RENAMED from AWS `cluster_oidc_issuer_url` / `oidc_provider_arn`.
#
# READ THIS BEFORE WIRING ANYTHING TO IT. On AWS the OIDC provider is the
# foundation IRSA is built on and every application module's trust policy
# references it. On OCI it is NOT the pod-identity mechanism: OKE Workload
# Identity needs no OIDC registration, only cluster_type = "enhanced". This
# endpoint exists so that AWS or GCP STS can validate an OKE pod's token - i.e.
# OKE -> other cloud, which is a migration-cutover path, not the steady state.
# `oke-workload-identity` should consume `cluster_id`, not this.
output "cluster_oidc_discovery_endpoint" {
  description = "OIDC discovery endpoint. NOT the OCI pod-identity mechanism (that is Workload Identity, keyed on cluster_id) - this is for federating OKE pods INTO AWS/GCP during cutover. Replaces AWS `cluster_oidc_issuer_url`; there is no `oidc_provider_arn` equivalent."
  value       = module.oke.cluster_oidc_discovery_endpoint
}

# -----------------------------------------------------------------------------
# Network Security Groups
# -----------------------------------------------------------------------------
# RENAMED from AWS `cluster_security_group_id` / `node_security_group_id` /
# `node_group_security_group_ids`. `security-rules` (phase 5) writes its
# cross-module rules into these; on OCI an NSG rule is a standalone resource, so
# it can do that from a different Terraform state without contending with this
# one. network-security-model.md section 5.

output "control_plane_nsg_id" {
  description = "NSG attached to the OKE API endpoint VNIC. Replaces AWS `cluster_security_group_id`."
  value       = module.oke.control_plane_nsg_id
}

output "worker_nsg_id" {
  description = "NSG attached to every worker-node VNIC. Replaces AWS `node_security_group_id`."
  value       = module.oke.worker_nsg_id
}

output "pod_nsg_id" {
  description = "NSG attached to pod VNICs when cni_type = 'npn'. No AWS equivalent - EKS pods share the node ENI's security groups. Counts against the hard 5-NSGs-per-VNIC cap."
  value       = try(module.oke.pod_nsg_id, null)
}

output "internal_lb_nsg_id" {
  description = "NSG for internal service load balancers."
  value       = try(module.oke.int_lb_nsg_id, null)
}

output "public_lb_nsg_id" {
  description = "NSG for public service load balancers."
  value       = try(module.oke.pub_lb_nsg_id, null)
}

output "custom_nsg_ids" {
  description = "Any additional NSG OCIDs managed by the wrapped module. Replaces AWS `node_group_security_group_ids`."
  value       = try(module.oke.custom_nsg_ids, {})
}

# -----------------------------------------------------------------------------
# Node pools
# -----------------------------------------------------------------------------

output "node_pool_ids" {
  description = "Map of node-pool name to OCID. Replaces AWS `eks_managed_node_groups`."
  value       = module.oke.worker_pool_ids
}

# THIS OUTPUT EXISTS BECAUSE OF A GAP, not because of a feature.
# `oci_containerengine_node_pool` has no min_size/max_size - only `size`. Unlike
# an AWS ASG or a GKE node pool, nothing at the compute layer keeps the pool
# inside a range when the autoscaler is unhealthy. The bounds live ONLY as
# external configuration, and this output is how they get there: the Cluster
# Autoscaler on OCI takes an explicit `--nodes=<min>:<max>:<pool-OCID>` flag per
# pool (there is no ASG-tag auto-discovery equivalent either), so
# oke-kubernetes-resources renders its flags from this map.
# See eks.md gap 4.5 and eks-kubernetes-resources.md gap 4.4.
output "node_pool_autoscaler_bounds" {
  description = "Per-pool advisory scaling bounds, NOT enforced by OCI or by this module. Shape: { <pool> = { min_size, max_size, pool_id } }. Feed to the Cluster Autoscaler's --nodes=<min>:<max>:<pool-OCID> flags. If no autoscaler consumes this, the pools have no floor and no ceiling."
  value = {
    for name, bounds in local.autoscaler_bounds : name => {
      min_size = bounds.min_size
      max_size = bounds.max_size
      pool_id  = try(module.oke.worker_pool_ids[name], null)
    }
  }
}

output "fault_domain_names" {
  description = "Fault domain names resolved live from data.oci_identity_fault_domains, intersected across every availability domain in the region. This is what an empty node_pools[*].fault_domains expands to. Published for the same reason kafka, cassandra and clickhouse publish theirs: so a reviewer can see the real names a plan is about to send rather than infer them."
  value       = local.region_fault_domains
}

output "node_pool_fault_domains" {
  description = "Per-pool fault domain placement actually sent to OKE, after empty lists expand to the full region set."
  value       = local.node_pool_fault_domains
}

output "node_pool_names" {
  description = "Names of the node pools created."
  value       = keys(var.node_pools)
}

# -----------------------------------------------------------------------------
# Placement facts downstream modules need
# -----------------------------------------------------------------------------

output "compartment_id" {
  description = "Compartment the cluster was created in. oke-kubernetes-resources needs it for the Block Volume and File Storage CSI storage-class parameters (`compartmentOcid`); oke-workload-identity needs it as the policy attachment point."
  value       = var.compartment_id
}

output "availability_domains" {
  description = "Availability domains in this region, as a map of AD number to name. ap-mumbai-1 has ONE - the File Storage CSI storage class needs the name for `availabilityDomain`, and node pools spread across fault domains rather than ADs because of it."
  value       = module.oke.availability_domains
}

output "vcn_id" {
  description = "VCN the cluster is in. Passed straight through from the input - this module never creates a VCN."
  value       = var.vcn_id
}

output "worker_subnet_id" {
  description = "Subnet worker nodes are placed in."
  value       = var.worker_subnet_id
}

output "pod_subnet_id" {
  description = "Subnet pod VNICs are placed in when cni_type = 'npn'."
  value       = local.pod_subnet_id
}

output "service_lb_subnet_id" {
  description = "Subnet OKE places a Service of type LoadBalancer in by default. Individual Services override it with the `oci.oraclecloud.com/load-balancer-subnet` annotation - there is no AWS-style subnet-tag discovery on OKE, so consumers of this output must set the annotation explicitly when they need the other tier (vpc-network.md gap 4.7)."
  value       = var.preferred_load_balancer == "public" ? var.public_lb_subnet_id : var.internal_lb_subnet_id
}

output "cni_type" {
  description = "Pod networking mode in use. oke-kubernetes-resources and the ingress modules branch on this."
  value       = var.cni_type
}

# -----------------------------------------------------------------------------
# SSH key (AWS feature 18)
# -----------------------------------------------------------------------------

output "node_ssh_private_key_secret_id" {
  description = "OCID of the Vault secret holding the generated node SSH private key. Replaces AWS's SSM parameter name. Null when create_ssh_key is false."
  value       = try(oci_vault_secret.node_pool_private_key[0].id, null)
}

output "node_ssh_public_key" {
  description = "Public half of the node SSH key actually in use."
  value       = local.ssh_public_key
}

# -----------------------------------------------------------------------------
# Features with no OCI counterpart - documented absences, not omissions
# -----------------------------------------------------------------------------
# The AWS module exports these; this one cannot, and a consumer that reaches for
# them should find this comment rather than a missing-output error with no
# explanation.
#
#   cluster_arn                  -> no ARNs on OCI; use cluster_id (an OCID).
#   cluster_iam_role_arn         -> feature 3 / gap 4.1: no assumable cluster
#                                   role exists to export.
#   ebs_csi_iam_role_arn         -> feature 9: folded into the Block Volume CSI
#                                   add-on, which authenticates as the
#                                   OKE-managed control plane. No identity
#                                   resource, so no output.
#   efs_csi_iam_role_arn         -> feature 10: same, for File Storage.
#   oidc_provider_arn            -> feature 7: OCI Workload Identity registers
#                                   no provider. Use cluster_id.
#   eks_managed_node_groups_iam_role_arn/_name
#                                -> feature 17 / gap 4.6: node permissions come
#                                   from a dynamic group in the IAM bootstrap,
#                                   not a role owned here.
#   cross_account_role_arn/_name -> feature 5 / gap 4.3: pending oracle gate.
#                                   Deliberately not exported as a null, so that
#                                   a consumer wiring it up fails loudly at
#                                   plan time rather than silently receiving
#                                   nothing.
