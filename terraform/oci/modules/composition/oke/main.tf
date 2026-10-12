# =============================================================================
# oke - OCI Container Engine for Kubernetes
# =============================================================================
# Port of terraform/aws/modules/composition/eks. Check sheet:
#   docs/multi-cloud-parity/oci/modules/eks.md   (verdict: HYBRID)
# Identity decision this module implements the prerequisite for:
#   docs/multi-cloud-parity/oci/identity-model.md  (OKE Workload Identity)
#
# STRATEGY: HYBRID, and the seam matters.
#
#   From the registry module (`oracle-terraform-modules/oke/oci ~> 5.5`,
#   verified publisher, 492,801 downloads, published 2026-08-18):
#   the cluster, node pools, cluster add-ons, the OKE NSG baseline, and the
#   OKE image resolution. Kubernetes cluster bootstrap is the single worst
#   thing to hand-roll, and this is the one OCI registry module that clears
#   framework.md section 3's verified/freshness bar
#   (provider-facts.md Tier 1).
#
#   NOT from the registry module - explicitly switched off below:
#   its VCN, subnets, gateways and route tables (composition/vpc-network owns
#   those), its bastion host (a future jump-host module owns that), its
#   operator host (no analogue in this stack; kubectl access is via the
#   bastion), and every convenience Helm installer (argocd, prometheus,
#   gatekeeper, cilium, metrics-server, cluster-autoscaler, karpenter,
#   multus, sriov, rdma, whereabouts, dcgm-exporter, mpi-operator).
#   ArgoCD is its own composition module and in-cluster workloads belong to
#   oke-kubernetes-resources; installing them from here would blur that seam,
#   and Oracle documents those toggles as unsupported extensions.
#
#   Added directly, outside the registry module, for gaps it does not cover:
#   ssh-key.tf (feature 18 / gap 4.7) and the named-but-unimplemented
#   cross-account inputs (feature 5 / gap 4.3).
# =============================================================================

module "oke" {
  source  = "oracle-terraform-modules/oke/oci"
  version = "~> 5.5"

  # The registry module declares `configuration_aliases = [oci.home]` because
  # its IAM sub-module writes dynamic groups and policies, which must be created
  # in the tenancy's home region. We hand it the default provider - the same
  # thing upstream's own `cluster-workers-only` example does.
  #
  # This is safe ONLY because create_iam_resources = false below, so no IAM
  # resource is created and no home-region API call is made. If that ever
  # changes, this line must become `oci.home = oci.home` AND every consuming
  # live root's hand-written root.hcl must generate a second
  # `provider "oci" { alias = "home" region = <home region> }` block.
  # NOTE: naming `oci` explicitly is required, not decorative. A `providers`
  # map disables the implicit inheritance of every provider it does not list,
  # so passing only `oci.home` would leave the child module with no default
  # `oci` configuration at all.
  providers = {
    oci      = oci
    oci.home = oci
  }

  # ---------------------------------------------------------------------------
  # Placement
  # ---------------------------------------------------------------------------
  region         = var.region
  tenancy_id     = var.tenancy_id
  compartment_id = var.compartment_id

  # SIMPLIFICATION, first cut: one flat compartment. Worker and network
  # resources land in the same compartment as the cluster, which also removes
  # the cross-compartment workload-mapping requirement described in
  # identity-model.md section 3.4 - a policy attached to this compartment covers
  # the cluster and everything its pods touch.
  worker_compartment_id  = var.compartment_id
  network_compartment_id = var.compartment_id

  # ---------------------------------------------------------------------------
  # Cluster (AWS features 1, 6, 7)
  # ---------------------------------------------------------------------------
  create_cluster     = true
  cluster_name       = local.cluster_name
  kubernetes_version = var.kubernetes_version

  # ENHANCED, not basic. This is the cluster-level prerequisite for OKE
  # Workload Identity, which identity-model.md picks as the IRSA equivalent for
  # all twelve identity-bearing application modules. Oracle, verbatim: "You can
  # only use workload identities to grant access to OCI resources when using
  # enhanced clusters." The registry module maps this to
  # ENHANCED_CLUSTER / BASIC_CLUSTER on `oci_containerengine_cluster.type`.
  # Basic here would make the entire identity model unimplementable.
  cluster_type = var.cluster_type

  cni_type      = var.cni_type
  pods_cidr     = var.pods_cidr
  services_cidr = var.services_cidr

  # Envelope encryption of Kubernetes Secrets with a customer-managed key -
  # the OKE analogue of AWS feature 6's KMS cluster encryption config.
  # Not coalesce(): coalesce() rejects "" as well as null, so a null key would
  # be a hard error rather than "no customer-managed key".
  cluster_kms_key_id = var.cluster_kms_key_id != null ? var.cluster_kms_key_id : ""

  # The OIDC *discovery* document. Not the pod-identity mechanism on OCI - see
  # the oidc_discovery_enabled variable comment. Kept on because it is the only
  # documented path for an OKE pod that must still authenticate to AWS or GCP
  # during cutover (identity-model.md section 5, Option C).
  oidc_discovery_enabled = var.oidc_discovery_enabled

  # PENDING ORACLE GATE (gap 4.3). OIDC token authentication is one of the two
  # candidate mechanisms for cross-tenancy CI/CD administration. Left off until
  # that decision lands rather than half-configured.
  oidc_token_auth_enabled = false

  # ---------------------------------------------------------------------------
  # Control-plane endpoint (AWS feature 2)
  # ---------------------------------------------------------------------------
  control_plane_is_public           = var.control_plane_is_public
  assign_public_ip_to_control_plane = var.assign_public_ip_to_control_plane

  # AWS enforces this with a first-class cluster-API allow-list plus a separate
  # VPN security-group rule. OKE has neither: both become ingress rules on the
  # NSG attached to the endpoint VNIC. Same outcome, different mechanism.
  control_plane_allowed_cidrs = var.control_plane_allowed_cidrs
  control_plane_nsg_ids       = var.additional_control_plane_nsg_ids

  # ---------------------------------------------------------------------------
  # Network - CONSUMED, NEVER CREATED
  # ---------------------------------------------------------------------------
  # composition/vpc-network owns the VCN, the 13-tier CIDR plan, the named route
  # tables, the gateways and the emptied default security list. Every creation
  # switch here is off, and every subnet is passed in by OCID.
  create_vcn = false
  vcn_id     = var.vcn_id

  vcn_create_internet_gateway = "never"
  vcn_create_nat_gateway      = "never"
  vcn_create_service_gateway  = "never"
  create_drg                  = false

  # No-op while create_vcn = false (the registry module only passes this to the
  # VCN it would have created), and deliberately left at the default: the VCN's
  # default security list is emptied by composition/vpc-network, which is the
  # state that owns it. network-security-model.md section 5 item 2.
  lockdown_default_seclist = true

  subnets                 = local.subnets
  nsgs                    = local.nsgs
  load_balancers          = local.load_balancers
  preferred_load_balancer = var.preferred_load_balancer
  backend_nsg_ids         = var.service_lb_backend_nsg_ids

  allow_worker_internet_access = var.allow_worker_internet_access
  allow_pod_internet_access    = var.allow_pod_internet_access
  allow_worker_ssh_access      = var.allow_worker_ssh_access
  allow_node_port_access       = false

  # ---------------------------------------------------------------------------
  # Bastion and operator - OFF
  # ---------------------------------------------------------------------------
  # Not "not needed yet": owned elsewhere. A bastion is a jump-host composition
  # module (jump-host.md); there is no operator-host concept in this stack at
  # all. Leaving these on would have the registry module build a second, unmanaged
  # SSH ingress path into the VCN.
  create_bastion  = false
  create_operator = false

  # ---------------------------------------------------------------------------
  # Node pools (AWS features 11-16)
  # ---------------------------------------------------------------------------
  worker_pool_mode = "node-pool"
  worker_pools     = local.worker_pools

  worker_image_type                     = "oke"
  worker_legacy_imds_endpoints_disabled = var.disable_legacy_imds_endpoints
  worker_block_volume_type              = var.worker_block_volume_type
  worker_volume_kms_key_id              = var.worker_volume_kms_key_id
  worker_nsg_ids                        = var.additional_worker_nsg_ids
  pod_nsg_ids                           = var.additional_pod_nsg_ids

  ssh_public_key = local.ssh_public_key

  # ---------------------------------------------------------------------------
  # Add-ons (AWS feature 8)
  # ---------------------------------------------------------------------------
  # No before/after-nodes split exists on OKE: the CNI and kube-proxy are
  # bootstrapped by the service at node-join time, not user-managed add-ons that
  # must land before the first node. AWS features 9 and 10 (the EBS and EFS CSI
  # IRSA roles) have no counterpart either - the Block Volume and File Storage
  # CSI drivers authenticate as the OKE-managed control plane.
  cluster_addons = var.cluster_addons

  # ---------------------------------------------------------------------------
  # IAM - deliberately not created here (AWS features 3 and 17, gaps 4.1/4.6)
  # ---------------------------------------------------------------------------
  # AWS gives the cluster and the node group each a named, assumable IAM role
  # with policies attached. OKE has neither.
  #   - Control-plane permissions come from tenancy/compartment policy
  #     statements written against the `oke` SERVICE PRINCIPAL, applied once for
  #     the tenancy rather than per cluster. There is no
  #     `create_iam_cluster_policy` toggle in the registry module at all.
  #   - Worker-node permissions come from DYNAMIC GROUP membership plus a policy
  #     written against that group. The registry module's
  #     `create_iam_worker_policy = "auto"` only fires for self-managed
  #     (non-node-pool) workers; OKE-managed node pools get their permissions
  #     from the service.
  # Both therefore belong to the phase-0 compartment/IAM bootstrap
  # (master-checksheet.md P5), not to a per-cluster module.
  #
  # Keeping this false is also what makes `providers = { oci.home = oci }` above
  # correct. Turning it on requires an aliased home-region provider from
  # root.hcl.
  #
  # KNOWN CONSEQUENCE, not silently absorbed: if `cluster_kms_key_id` is set,
  # the dynamic group and `use keys` policy the cluster needs to reach that key
  # are NOT created here and must come from the IAM bootstrap.
  create_iam_resources = false

  # ---------------------------------------------------------------------------
  # Convenience installers - ALL OFF
  # ---------------------------------------------------------------------------
  # Each of these would have the composition layer run Helm. ArgoCD is its own
  # composition module; everything else in-cluster belongs to
  # oke-kubernetes-resources (phase 2) or to the app units (phase 3).
  # cluster_autoscaler_install and karpenter_install are additionally blocked on
  # the oracle gate in eks.md section 8 item 4 - which autoscaler fills the
  # min/max gap is a genuine architecture fork, not a flag.
  argocd_install              = false
  prometheus_install          = false
  gatekeeper_install          = false
  cilium_install              = false
  metrics_server_install      = false
  cluster_autoscaler_install  = false
  karpenter_install           = false
  multus_install              = false
  whereabouts_install         = false
  sriov_device_plugin_install = false
  rdma_cni_plugin_install     = false
  dcgm_exporter_install       = false
  mpi_operator_install        = false
  create_service_account      = false

  # ---------------------------------------------------------------------------
  # Tagging and output
  # ---------------------------------------------------------------------------
  # output_detail = true is required for the module to export cluster_ca_cert
  # and the kubeconfig, which oke-kubernetes-resources (phase 2) needs to
  # configure its kubernetes/helm providers.
  output_detail = true

  use_defined_tags = false
  freeform_tags = {
    bastion           = local.common_freeform_tags
    cluster           = local.common_freeform_tags
    iam               = local.common_freeform_tags
    network           = local.common_freeform_tags
    operator          = local.common_freeform_tags
    persistent_volume = local.common_freeform_tags
    service_lb        = local.common_freeform_tags
    workers           = local.common_freeform_tags
  }
}

# -----------------------------------------------------------------------------
# Cross-variable preconditions
# -----------------------------------------------------------------------------
# Terraform variable validation cannot reference another variable below 1.9, and
# this repo's modules target >= 1.5, so cross-variable checks live here. Same
# technique the registry module uses (`null_resource.validate_subnets`).
resource "terraform_data" "validate" {
  input = local.cluster_name

  lifecycle {
    precondition {
      condition     = var.public_lb_subnet_id != null || var.internal_lb_subnet_id != null
      error_message = "At least one of public_lb_subnet_id or internal_lb_subnet_id must be set: OKE records a default service load-balancer subnet on the cluster itself, and unlike AWS there is no subnet-tag discovery to fall back on (vpc-network.md gap 4.7)."
    }

    precondition {
      condition     = var.preferred_load_balancer != "public" || var.public_lb_subnet_id != null
      error_message = "preferred_load_balancer = 'public' requires public_lb_subnet_id."
    }

    precondition {
      condition     = var.preferred_load_balancer != "internal" || var.internal_lb_subnet_id != null
      error_message = "preferred_load_balancer = 'internal' requires internal_lb_subnet_id."
    }

    precondition {
      condition     = !var.assign_public_ip_to_control_plane || var.control_plane_is_public
      error_message = "assign_public_ip_to_control_plane requires control_plane_is_public - OCI cannot attach a public IP to an endpoint in a private subnet."
    }

    precondition {
      condition     = !var.control_plane_is_public || length(var.control_plane_allowed_cidrs) > 0
      error_message = "A public control-plane endpoint with an empty control_plane_allowed_cidrs list has no ingress allow-list. Supply the VPN/office CIDRs (AWS's cluster_endpoint_public_access_cidrs and its VPN security-group rule merge into this one list on OCI)."
    }

    # ---------------------------------------------------------------------
    # Fault domains (build-log C16)
    # ---------------------------------------------------------------------
    # These two are here rather than in a variable `validation` block because
    # a variable validation cannot reference a data source, and the only check
    # worth having is against the names the tenancy actually publishes.
    precondition {
      condition     = length(local.region_fault_domains) > 0
      error_message = "No fault domain name is common to every availability domain in ${var.region}. Every node pool would then be created with an empty placement list. Inspect data.oci_identity_fault_domains.this - this is either an authorisation failure on the identity API or a region whose ADs genuinely disagree, and neither should be absorbed silently."
    }

    precondition {
      condition = alltrue([
        for _, fds in local.node_pool_fault_domains :
        alltrue([for fd in fds : contains(local.region_fault_domains, fd)])
      ])
      error_message = "node_pools[*].fault_domains must contain live fault domain NAMES. Available in ${var.region}: ${join(", ", local.region_fault_domains)}. The short 'FD-N' form is not an OCI name - it is the oracle-terraform-modules/oke/oci module's internal virtual-node-pool placeholder, it is passed through untranslated on the managed node-pool path, and OKE rejects it with '400-InvalidParameter, Invalid nodeConfigDetails.placementConfigs[].faultDomains'. Leave the list empty to spread across every fault domain."
    }
  }
}
