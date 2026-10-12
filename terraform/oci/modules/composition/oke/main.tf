# oke - OCI Container Engine for Kubernetes.

module "oke" {
  source  = "oracle-terraform-modules/oke/oci"
  version = "~> 5.5"

  # The registry module declares `configuration_aliases = [oci.home]` for its
  # home-region IAM writes. Handing it the default provider is safe ONLY
  # because create_iam_resources = false below. If that ever changes, this
  # must become `oci.home = oci.home` AND every consuming root.hcl must add a
  # second `provider "oci" { alias = "home" }` block. Naming `oci` explicitly
  # is required: a `providers` map disables implicit inheritance of every
  # provider it does not list.
  providers = {
    oci      = oci
    oci.home = oci
  }

  region         = var.region
  tenancy_id     = var.tenancy_id
  compartment_id = var.compartment_id

  # SIMPLIFICATION: one flat compartment covers the cluster and everything its
  # pods touch, removing cross-compartment workload mapping.
  worker_compartment_id  = var.compartment_id
  network_compartment_id = var.compartment_id

  create_cluster     = true
  cluster_name       = local.cluster_name
  kubernetes_version = var.kubernetes_version

  # ENHANCED, not basic: the prerequisite for OKE Workload Identity (the IRSA
  # equivalent). Oracle: "You can only use workload identities to grant access
  # to OCI resources when using enhanced clusters." Basic would make the entire
  # identity model unimplementable.
  cluster_type = var.cluster_type

  cni_type      = var.cni_type
  pods_cidr     = var.pods_cidr
  services_cidr = var.services_cidr

  # Envelope encryption of Kubernetes Secrets with a customer-managed key. Not
  # coalesce(): coalesce() rejects "" too, so a null key must be a hard error
  # rather than "no customer-managed key".
  cluster_kms_key_id = var.cluster_kms_key_id != null ? var.cluster_kms_key_id : ""

  # The OIDC *discovery* document, not the pod-identity mechanism (see the
  # oidc_discovery_enabled variable comment). Kept on because it is the only
  # documented path for an OKE pod that must still authenticate to AWS/GCP
  # during cutover.
  oidc_discovery_enabled = var.oidc_discovery_enabled

  # OIDC token authentication left off until the cross-tenancy CI/CD decision
  # lands.
  oidc_token_auth_enabled = false

  control_plane_is_public           = var.control_plane_is_public
  assign_public_ip_to_control_plane = var.assign_public_ip_to_control_plane

  # AWS's cluster-API allow-list and its VPN security-group rule both become
  # ingress rules on the endpoint NSG on OKE - same outcome, one mechanism.
  control_plane_allowed_cidrs = var.control_plane_allowed_cidrs
  control_plane_nsg_ids       = var.additional_control_plane_nsg_ids

  # composition/vpc-network owns the VCN, subnets, route tables, gateways and
  # the emptied default security list; every creation switch here is off.
  create_vcn = false
  vcn_id     = var.vcn_id

  vcn_create_internet_gateway = "never"
  vcn_create_nat_gateway      = "never"
  vcn_create_service_gateway  = "never"
  create_drg                  = false

  # No-op while create_vcn = false, and deliberately left at the default: the
  # VCN's default security list is emptied by composition/vpc-network, which
  # owns that state.
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

  # Off here because they are owned elsewhere: a bastion is a future jump-host
  # module, and there is no operator-host concept in this stack. Leaving them
  # on would have the registry module build a second, unmanaged SSH ingress
  # path into the VCN.
  create_bastion  = false
  create_operator = false

  worker_pool_mode = "node-pool"
  worker_pools     = local.worker_pools

  worker_image_type                     = "oke"
  worker_legacy_imds_endpoints_disabled = var.disable_legacy_imds_endpoints
  worker_block_volume_type              = var.worker_block_volume_type
  worker_volume_kms_key_id              = var.worker_volume_kms_key_id
  worker_nsg_ids                        = var.additional_worker_nsg_ids
  pod_nsg_ids                           = var.additional_pod_nsg_ids

  ssh_public_key = local.ssh_public_key

  # No before/after-nodes split exists on OKE: the CNI and kube-proxy are
  # service-bootstrapped, not user-managed add-ons. The EBS/EFS CSI IRSA roles
  # have no counterpart either - the CSI drivers authenticate as the OKE-managed
  # control plane.
  cluster_addons = var.cluster_addons

  # IAM is deliberately not created here: control-plane permissions come from
  # tenancy/compartment policies written against the `oke` service principal,
  # and OKE-managed worker-node permissions come from the service itself (the
  # registry module's create_iam_worker_policy = "auto" only fires for
  # self-managed workers). Both belong to the phase-0 compartment/IAM bootstrap.
  #
  # Keeping this false is also what makes `providers = { oci.home = oci }`
  # correct; turning it on requires an aliased home-region provider in root.hcl.
  #
  # KNOWN CONSEQUENCE: if `cluster_kms_key_id` is set, the dynamic group and
  # `use keys` policy the cluster needs are NOT created here and must come from
  # the IAM bootstrap.
  create_iam_resources = false

  # Each of these would have the composition layer run Helm; ArgoCD is its own
  # module and everything else belongs to oke-kubernetes-resources or the app
  # units. cluster_autoscaler_install and karpenter_install are additionally
  # blocked pending a decision on the min/max gap.
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

  # output_detail = true is required for the module to export cluster_ca_cert and
  # the kubeconfig, which oke-kubernetes-resources needs.
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

# Cross-variable preconditions. Terraform variable validation cannot reference
# another variable below 1.9 (this repo targets >= 1.5), so these live here.
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

    # Fault domains: checked here because a variable validation cannot reference a
    # data source, and the only check worth having is against the names the
    # tenancy actually publishes.
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
