# ============================================================================
# OKE Cluster (using the official, verified oracle-terraform-modules/oke/oci
# registry module) - equivalent of the AWS eks composition module which
# wraps terraform-aws-modules/eks.
#
# create_vcn = false: the VCN and all subnets are owned by the vpc-network
# composition module; this module only attaches to them (mirrors how the AWS
# eks module takes vpc_id/subnet_ids as inputs rather than creating a VPC).
# ============================================================================
module "oke" {
  source  = "oracle-terraform-modules/oke/oci"
  version = "5.5.0"

  providers = {
    oci      = oci
    oci.home = oci.home
  }

  compartment_id = var.compartment_id

  # Reuse existing network from the vpc-network composition module
  create_vcn = false
  vcn_id     = var.vcn_id

  subnets = {
    workers  = { id = var.workers_subnet_id, create = "never" }
    cp       = { id = var.control_plane_subnet_id, create = "never" }
    pub_lb   = { id = var.public_lb_subnet_id, create = "never" }
    int_lb   = var.internal_lb_subnet_id != null ? { id = var.internal_lb_subnet_id, create = "never" } : { create = "never" }
    bastion  = { create = "never" }
    operator = { create = "never" }
    pods     = { create = "never" }
  }

  nsgs = {
    bastion  = { create = "never" }
    operator = { create = "never" }
    cp       = { create = "auto" }
    int_lb   = { create = "auto" }
    pub_lb   = { create = "auto" }
    workers  = { create = "auto" }
    pods     = { create = "auto" }
  }

  # Cluster
  cluster_name                = var.cluster_name
  kubernetes_version          = var.kubernetes_version
  control_plane_is_public     = var.control_plane_is_public
  control_plane_allowed_cidrs = var.control_plane_allowed_cidrs
  cni_type                    = var.cni_type
  pods_cidr                   = var.pods_cidr
  services_cidr               = var.services_cidr

  # OIDC discovery (OKE's equivalent of the EKS OIDC provider used for IRSA;
  # used here for OKE Workload Identity)
  oidc_discovery_enabled = true

  # Workers
  worker_pools   = var.worker_pools
  ssh_public_key = var.ssh_public_key

  state_id = "${var.environment}-${var.project_name}"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}
