# =============================================================================
# oke - input surface
# =============================================================================
# Ported from terraform/aws/modules/composition/eks/variables.tf (41 variables).
# Divergences from the AWS surface are commented at the variable that embodies
# them; the full rationale is in docs/multi-cloud-parity/oci/modules/eks.md.
# =============================================================================

# -----------------------------------------------------------------------------
# Identity of the deployment
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name, used as the leading component of every generated resource name."
  type        = string
}

variable "environment" {
  description = "Short environment identifier (dev, integ, sandbox, prod)."
  type        = string
}

variable "region" {
  description = "OCI region identifier the cluster is created in, e.g. ap-mumbai-1."
  type        = string
}

# DIVERGENCE (new input, no AWS analogue). AWS resources live in an account
# that the provider credentials already imply. On OCI every resource is
# compartment-scoped and the compartment must be named explicitly. Forced by
# the platform, not a design choice. See eks.md section 5.
variable "compartment_id" {
  description = "OCID of the compartment the cluster, node pools and NSGs are created in. First cut uses one flat compartment for the whole environment."
  type        = string

  validation {
    condition     = startswith(var.compartment_id, "ocid1.compartment.") || startswith(var.compartment_id, "ocid1.tenancy.")
    error_message = "compartment_id must be a compartment or tenancy OCID."
  }
}

# OPTIONAL, deliberately. The registry module uses it for its
# availability-domain lookup and would need it for any tenancy-root resource
# (dynamic groups only exist in the tenancy root) - but this module creates no
# IAM resources, and the AD lookup falls back to `compartment_id` when the
# tenancy is unknown, which is verified to work in ap-mumbai-1. Making this
# required would put a tenancy OCID in every live root`s root.hcl for no gain.
variable "tenancy_id" {
  description = "OCID of the tenancy. Optional - only needed if IAM resources are ever created from this module; the availability-domain lookup falls back to compartment_id."
  type        = string
  default     = null

  validation {
    condition     = var.tenancy_id == null || startswith(coalesce(var.tenancy_id, "x"), "ocid1.tenancy.")
    error_message = "tenancy_id must be a tenancy OCID when set."
  }
}

variable "freeform_tags" {
  description = "Freeform tags applied to every resource this module creates. OCI's analogue of AWS `tags`."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Cluster
# -----------------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the OKE cluster. Defaults to <project_name>-<environment>-oke."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version for the control plane and, unless overridden per pool, for node pools. Must be a version OKE currently offers in this region - confirm with `oci ce cluster-options get --cluster-option-id all` before changing."
  type        = string
  default     = "v1.34.2"

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must be of the form vX.Y.Z."
  }
}

# DIVERGENCE (new input, no AWS analogue). EKS has no basic/enhanced cluster
# distinction. OKE does, and OKE Workload Identity - the mechanism
# docs/multi-cloud-parity/oci/identity-model.md picks as the IRSA equivalent
# for all twelve identity-bearing application modules - is available on
# ENHANCED clusters only. Oracle, verbatim: "You can only use workload
# identities to grant access to OCI resources when using enhanced clusters."
# Defaulting to basic here would silently make the whole identity model
# unimplementable, so the default is "enhanced" and downgrading is a
# deliberate act.
variable "cluster_type" {
  description = "OKE cluster tier. Must be 'enhanced': OKE Workload Identity (the pod-identity mechanism this programme depends on) is available on enhanced clusters only."
  type        = string
  default     = "enhanced"

  # Restricted to "enhanced" on purpose. "basic" is a mechanically valid OKE
  # value, but selecting it silently removes Workload Identity and therefore
  # breaks all twelve identity-bearing application modules with no plan-time
  # signal anywhere near them. Relaxing this is an oracle-gate change to
  # identity-model.md, not a per-environment knob.
  validation {
    condition     = lower(var.cluster_type) == "enhanced"
    error_message = "cluster_type must be 'enhanced'. OKE Workload Identity - the IRSA equivalent every application module in this programme is written against (docs/multi-cloud-parity/oci/identity-model.md) - is available on enhanced clusters only. Oracle, verbatim: \"You can only use workload identities to grant access to OCI resources when using enhanced clusters.\""
  }
}

# DIVERGENCE. AWS's IP-per-pod is `vpc-cni` and is the default. OCI's default
# is Flannel (an overlay); VCN-native pod networking has to be asked for. `npn`
# is the parity choice - pods get a real, VCN-routable IP, which is what makes
# per-pod NSGs (network-security-model.md) and pod-level route policy possible
# at all.
variable "cni_type" {
  description = "Pod networking: 'npn' (VCN-native, pods get real VCN IPs - the AWS vpc-cni / GCP IP-alias equivalent) or 'flannel' (overlay)."
  type        = string
  default     = "npn"

  validation {
    condition     = contains(["npn", "flannel"], var.cni_type)
    error_message = "cni_type must be 'npn' or 'flannel'."
  }
}

variable "pods_cidr" {
  description = "CIDR used by pods. Ignored when cni_type = 'npn' (pods then take addresses from pod_subnet_id)."
  type        = string
  default     = "10.244.0.0/16"
}

variable "services_cidr" {
  description = "CIDR used by Kubernetes ClusterIP services. Must not overlap the VCN."
  type        = string
  default     = "10.96.0.0/16"
}

# -----------------------------------------------------------------------------
# Control-plane endpoint exposure (AWS feature 2)
# -----------------------------------------------------------------------------
# DIVERGENCE in mechanism, not outcome. AWS exposes
# `cluster_endpoint_public_access_cidrs` as a first-class cluster-API
# allow-list, and the VPN rule is a separate security-group rule. OKE has no
# such field: the allow-list is expressed as ingress rules on the NSG attached
# to the cluster endpoint. So AWS's `cluster_endpoint_public_access_cidrs` and
# its `security_group_additional_rules.vpn_access` MERGE into this one list.

variable "control_plane_is_public" {
  description = "Whether the Kubernetes API endpoint sits in a public subnet."
  type        = bool
  default     = false
}

variable "assign_public_ip_to_control_plane" {
  description = "Whether the API endpoint gets a public IP. Requires control_plane_is_public."
  type        = bool
  default     = false
}

variable "control_plane_allowed_cidrs" {
  description = "CIDRs permitted to reach the Kubernetes API on 6443. Merges AWS's cluster_endpoint_public_access_cidrs and its separate VPN security-group rule, because OKE enforces both through the same endpoint NSG."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Network - supplied by composition/vpc-network, never created here
# -----------------------------------------------------------------------------
# The registry module can build its own VCN, subnets and gateways. That surface
# is switched off (see main.tf): this programme has a dedicated `vpc-network`
# composition module that owns the 13-tier CIDR plan, the named route tables and
# the emptied default security list. Two modules creating VCN plumbing is how a
# port forks.

variable "vcn_id" {
  description = "OCID of the existing VCN from composition/vpc-network. This module never creates a VCN."
  type        = string

  validation {
    condition     = startswith(var.vcn_id, "ocid1.vcn.")
    error_message = "vcn_id must be a VCN OCID."
  }
}

variable "control_plane_subnet_id" {
  description = "OCID of the subnet hosting the OKE API endpoint VNIC."
  type        = string
}

variable "worker_subnet_id" {
  description = "OCID of the subnet worker-node VNICs are placed in (the `oke-nodes` tier)."
  type        = string
}

# GAP, recorded rather than papered over. With cni_type = 'npn' every pod
# consumes an IP from a real subnet. If vpc-network does not (yet) publish a
# dedicated pod tier, leaving this null makes pods share the worker subnet -
# legal on OCI and the registry module's own default, but it means node and pod
# addresses draw from the same pool and the tier must be sized for
# nodes + (nodes x max_pods_per_node). Prefer a dedicated pod tier.
variable "pod_subnet_id" {
  description = "OCID of the subnet pod VNICs are placed in when cni_type = 'npn'. Null means pods share worker_subnet_id - see the sizing warning in the variable comment."
  type        = string
  default     = null
}

variable "public_lb_subnet_id" {
  description = "OCID of the subnet OKE creates public service load balancers in. Null disables the public LB subnet entirely."
  type        = string
  default     = null
}

variable "internal_lb_subnet_id" {
  description = "OCID of the subnet OKE creates internal service load balancers in. Null disables the internal LB subnet entirely."
  type        = string
  default     = null
}

# DIVERGENCE. On AWS the ALB controller discovers subnets from the
# `kubernetes.io/role/elb` tag, so subnet selection is a network-module
# concern. OKE has no tag convention: the cluster records one default service
# LB subnet, and individual Services override it with the
# `oci.oraclecloud.com/load-balancer-subnet` annotation. See vpc-network.md 4.7.
variable "preferred_load_balancer" {
  description = "Which LB subnet OKE picks by default for a Service of type LoadBalancer: 'internal' or 'public'."
  type        = string
  default     = "internal"

  validation {
    condition     = contains(["internal", "public"], var.preferred_load_balancer)
    error_message = "preferred_load_balancer must be 'internal' or 'public'."
  }
}

# -----------------------------------------------------------------------------
# Network Security Groups (AWS features 2 and 16)
# -----------------------------------------------------------------------------
# network-security-model.md picks Option A (NSGs only, no per-tier security
# lists) and puts cross-module rules in a last-phase `security-rules` unit. NSG
# *membership* stays with the module that owns the VNIC - which is this one for
# the endpoint, nodes and pods.
#
# By default this module lets the registry module create the OKE NSGs and
# populate them with Oracle's own control-plane/worker/pod baseline (kubelet
# 10250, apiserver 6443, OKE 12250, OSN egress, pod-to-pod). Hand-porting those
# would be porting plumbing, not the security model. `security-rules` adds its
# rules to the same NSGs later - safe, because on OCI an NSG rule is a
# standalone resource, so two Terraform states never contend over one NSG.
variable "nsg_ids" {
  description = "Optional map of pre-existing NSG OCIDs by role - keys: cp, workers, pods, int_lb, pub_lb. Any role supplied here is attached as-is and the registry module creates nothing for it (and therefore writes NO baseline rules into it - you own the full rule set). Any role omitted is created here with Oracle's baseline rules."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for k in keys(var.nsg_ids) : contains(["cp", "workers", "pods", "int_lb", "pub_lb"], k)])
    error_message = "nsg_ids keys must be a subset of: cp, workers, pods, int_lb, pub_lb."
  }
}

variable "additional_control_plane_nsg_ids" {
  description = "Extra NSG OCIDs attached to the cluster endpoint VNIC in addition to the one this module manages. Watch the hard 5-NSGs-per-VNIC cap."
  type        = list(string)
  default     = []
}

variable "additional_worker_nsg_ids" {
  description = "Extra NSG OCIDs attached to every worker VNIC. Watch the hard 5-NSGs-per-VNIC cap (OKE already uses ~2)."
  type        = list(string)
  default     = []
}

variable "additional_pod_nsg_ids" {
  description = "Extra NSG OCIDs attached to pod VNICs when cni_type = 'npn'."
  type        = list(string)
  default     = []
}

variable "service_lb_backend_nsg_ids" {
  description = "NSG OCIDs registered as service load-balancer backends (options.service_lb_config.backend_nsg_ids)."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Node pools (AWS features 11-16)
# -----------------------------------------------------------------------------
# RENAMED from AWS `node_groups`. OCI's own term is "node pool", and GCP's port
# already made the same rename, so carrying `node_groups` across would make
# every reader translate twice.
#
# TWO GAPS ARE ENCODED IN THIS TYPE - read them before adding a pool:
#
# 1. ONE SHAPE PER POOL (eks.md gap 4.4). An AWS node group takes a LIST of
#    instance_types and the ASG picks from it for capacity availability; the
#    live sandbox `systems` group uses four. `oci_containerengine_node_pool`
#    takes exactly one `node_shape`. Express one AWS group with N candidate
#    types as N narrower pools here, sharing labels and placement.
#
# 2. NO COMPUTE-LAYER MIN/MAX (eks.md gap 4.5 - the most consequential gap in
#    this module). `aws_eks_node_group.scaling_config` has min_size/max_size
#    backed by an ASG that keeps enforcing them even if the autoscaler is dead.
#    `oci_containerengine_node_pool.node_config_details` has ONLY `size`. There
#    is no min_size or max_size argument on the resource, at all.
#    `min_size`/`max_size` below are therefore NOT enforced by this module or by
#    OCI. They are carried purely so `oke-kubernetes-resources` can render the
#    Cluster Autoscaler's `--nodes=<min>:<max>:<pool-OCID>` flags from the
#    `node_pool_autoscaler_bounds` output. If the autoscaler is unhealthy or
#    misconfigured, nothing pulls the pool back inside those bounds.
#    Compensating control: alarm on node-pool `size` leaving its intended range.
variable "node_pools" {
  description = "OKE node pools, keyed by pool name. See the block comment above this variable for the two structural gaps versus AWS node groups (single shape per pool; min_size/max_size are advisory metadata, not enforced)."
  type = map(object({
    # Shape. `ocpus` / `memory_in_gbs` apply only to Flex shapes.
    shape         = optional(string, "VM.Standard.E5.Flex")
    ocpus         = optional(number, 2)
    memory_in_gbs = optional(number, 16)

    # Desired node count. The ONLY count OCI enforces.
    size = number

    # Advisory only - see gap 2 in the block comment above.
    enable_autoscaler = optional(bool, false)
    min_size          = optional(number)
    max_size          = optional(number)

    boot_volume_size_in_gbs = optional(number, 50)

    # image_type "oke" lets Oracle resolve the current supported OKE image for
    # the shape and Kubernetes version - the analogue of AWS's SSM
    # latest-AMI lookup, but done by Oracle rather than by this module.
    # "custom" requires image_id and is the analogue of a per-group custom AMI.
    image_type = optional(string, "oke")
    image_id   = optional(string)

    # Fault domain NAMES, NOT availability domains and NOT ordinals.
    # ap-mumbai-1 has ONE availability domain, so the EKS/GKE habit of spreading
    # a pool across AZs has no equivalent; the fault domains within the single
    # AD are the only in-region spread available.
    #
    # EMPTY IS THE INTENDED VALUE. Empty resolves to every fault domain the
    # region actually publishes, via data.oci_identity_fault_domains - the same
    # contract as kafka/cassandra/clickhouse's var.fault_domains. Set it only to
    # pin a pool to a subset, and then only to names the data source returns.
    #
    # DO NOT write the short "FD-1" form here. It is not an OCI name; it is the
    # wrapped registry module's internal virtual-node-pool placeholder
    # (`formatlist("FD-%v", [1,2,3])`), it is never translated on the managed
    # node-pool path, and the OKE API rejects it:
    #   400-InvalidParameter, Invalid
    #   nodeConfigDetails.placementConfigs[].faultDomains: Invalid FD name
    # This default used to be exactly that list and it failed a real apply -
    # build-log entry C16. Values are checked against the live data source in
    # main.tf's terraform_data.validate, not against a literal allow-list here,
    # because a static allow-list is what produced the bug.
    fault_domains = optional(list(string), [])

    node_labels       = optional(map(string), {})
    max_pods_per_node = optional(number, 31)
    subnet_id         = optional(string)
    # Additive: concatenated with the managed worker NSG, not a replacement.
    nsg_ids = optional(list(string), [])
    # NOTE: pod NSGs are deliberately module-level only (additional_pod_nsg_ids).
    # A per-pool pod_nsg_ids key REPLACES rather than extends the managed pod
    # NSG on `oci_containerengine_node_pool` in the registry module (its
    # `pods_nsg_ids` concat local is not the value the node-pool resource
    # reads), which would silently detach the baseline pod rules.
    volume_kms_key_id  = optional(string)
    cloud_init         = optional(list(map(string)), [])
    kubernetes_version = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for _, p in var.node_pools : p.size >= 0])
    error_message = "node_pools[*].size must be >= 0."
  }

  validation {
    condition     = alltrue([for _, p in var.node_pools : contains(["oke", "platform", "custom"], p.image_type)])
    error_message = "node_pools[*].image_type must be 'oke', 'platform' or 'custom'."
  }

  validation {
    condition     = alltrue([for _, p in var.node_pools : p.image_type != "custom" || p.image_id != null])
    error_message = "node_pools[*].image_id is required when image_type = 'custom'."
  }

  validation {
    condition     = alltrue([for _, p in var.node_pools : !p.enable_autoscaler || (p.min_size != null && p.max_size != null)])
    error_message = "node_pools[*].min_size and max_size are required when enable_autoscaler = true - they are the bounds the external Cluster Autoscaler will be given, since OKE node pools cannot enforce them."
  }

  validation {
    condition     = alltrue([for _, p in var.node_pools : !p.enable_autoscaler || (p.min_size <= p.size && p.size <= p.max_size)])
    error_message = "node_pools[*].size must lie within [min_size, max_size]."
  }

  # NOTE: there is deliberately no `validation` block for fault_domains here.
  # A variable validation cannot read a data source, so any check written at
  # this level can only compare against a hardcoded name list - which is the
  # exact construct that produced the C16 failure. The check lives in
  # main.tf's terraform_data.validate, against local.region_fault_domains.
}

# DIVERGENCE. AWS's `aws_launch_template.default` sets IMDSv2-only metadata and
# an encrypted gp3 root volume. OKE's equivalents are these two switches; boot
# and block volumes are encrypted at rest by default on OCI with no customer
# key, so there is no `encrypted = true` to port - the AWS setting has no
# counterpart because the weaker state does not exist.
variable "disable_legacy_imds_endpoints" {
  description = "Disable IMDSv1 on worker nodes. The OCI analogue of AWS's http_tokens = 'required'."
  type        = bool
  default     = true
}

variable "worker_volume_kms_key_id" {
  description = "OCID of a Vault key used for worker boot/block volume encryption. Null uses OCI's own default encryption, which is already on."
  type        = string
  default     = null
}

variable "worker_block_volume_type" {
  description = "Attachment type for worker block volumes: paravirtualized or iscsi."
  type        = string
  default     = "paravirtualized"
}

variable "allow_worker_internet_access" {
  description = "Whether the managed worker NSG permits egress to the internet. False matches the AWS `EKSWorker` route table, which deliberately has no 0.0.0.0/0 route and forces egress through the Squid proxy."
  type        = bool
  default     = false
}

variable "allow_pod_internet_access" {
  description = "Whether the managed pod NSG permits egress to the internet. Ignored when cni_type != 'npn'."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Add-ons (AWS feature 8)
# -----------------------------------------------------------------------------
# DIVERGENCE, and a simplification. The AWS module has to split addons into
# `before_nodes` and `after_nodes` because the VPC CNI and kube-proxy must exist
# before a node can join. On OKE the CNI and kube-proxy are bootstrapped by the
# service at node-join time and are not user-managed addons, so the whole
# sequencing apparatus (`local.addons_before_nodes`, the two `aws_eks_addon`
# resources) has no counterpart. Likewise features 9 and 10: the Block Volume
# and File Storage CSI drivers authenticate as the OKE-managed control plane,
# so `ebs_csi_irsa` / `efs_csi_irsa` disappear with no loss of capability.
variable "cluster_addons" {
  description = "OKE cluster add-ons, keyed by add-on name (e.g. CertManager, OracleDatabaseOperator). No before/after-nodes ordering exists or is needed - CNI and kube-proxy are service-managed."
  type        = any
  default     = {}
}

# -----------------------------------------------------------------------------
# Secrets envelope encryption (AWS feature 6)
# -----------------------------------------------------------------------------
variable "cluster_kms_key_id" {
  description = "OCID of a Vault key used as the master encryption key for Kubernetes Secrets. GAP: setting this alone is not sufficient - because create_iam_resources is false (see main.tf), the dynamic group and 'use keys' policy that let the cluster reach the key must be created by the phase-0 IAM/compartment bootstrap. See eks.md gap 4.1."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# SSH key for node access (AWS feature 18)
# -----------------------------------------------------------------------------
# PARTIAL (eks.md gap 4.7). AWS auto-generates an RSA keypair and stores the
# private half in SSM Parameter Store as a SecureString. The registry module
# accepts an existing public key only - it neither generates nor persists one.
# The two resources are therefore added directly in ssh-key.tf, targeting OCI
# Vault (the SSM SecureString analogue).
variable "create_ssh_key" {
  description = "Generate an SSH keypair for worker-node access and store the private half in OCI Vault. Mirrors AWS's create_ssh_key + aws_ssm_parameter pair."
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "Existing SSH public key material for worker nodes. Ignored when create_ssh_key is true."
  type        = string
  default     = null
}

variable "ssh_key_vault_id" {
  description = "OCID of the OCI Vault the generated private key is written to. Required when create_ssh_key is true."
  type        = string
  default     = null
}

variable "ssh_key_kms_key_id" {
  description = "OCID of the Vault master key used to encrypt the stored private key. Required when create_ssh_key is true."
  type        = string
  default     = null
}

variable "allow_worker_ssh_access" {
  description = "Whether the managed worker NSG permits inbound SSH. Independent of whether a key exists."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Cross-account administration (AWS feature 5) - NOT IMPLEMENTED, GATE PENDING
# -----------------------------------------------------------------------------
# eks.md gap 4.3. AWS creates an IAM role in this account whose trust policy
# admits ArgoCD's and Atlantis's role ARNs from the management account, so
# cross-account CI/CD can administer this cluster. OCI has no equivalent: IAM
# policies and dynamic groups are tenancy-scoped and there is no
# AssumeRole-across-accounts primitive. The two candidate mechanisms - OIDC
# federation via the cluster's oidc_token_authentication_config, or a
# same-tenancy dynamic group if the management cluster relocates to OCI - are
# architecturally different from each other and the choice is an oracle-gate
# item (framework.md 4.4).
#
# Kept as named-but-unimplemented inputs, per eks.md section 5, so that the
# feature is visibly outstanding rather than silently dropped. The validation
# makes turning it on a hard error with an explanation, not a silent no-op.
variable "create_cross_account_admin_access" {
  description = "PENDING ORACLE GATE - not implemented. Placeholder for AWS feature 5 (cross-account cluster administration by ArgoCD/Atlantis). Setting this true is a hard error until eks.md gap 4.3 is decided."
  type        = bool
  default     = false

  validation {
    condition     = var.create_cross_account_admin_access == false
    error_message = "create_cross_account_admin_access is not implemented. AWS's cross-account IAM role (feature 5) has no OCI counterpart; the replacement is an oracle-gate decision between OIDC federation (oidc_token_authentication_config) and a same-tenancy dynamic group, and depends on whether ArgoCD/Atlantis relocate to OCI. See docs/multi-cloud-parity/oci/modules/eks.md gap 4.3 and section 8 item 3."
  }
}

variable "cross_account_admin_principals" {
  description = "PENDING ORACLE GATE - not implemented. Placeholder for the principals AWS's cross_account_assume_role_policy trusts."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# OIDC
# -----------------------------------------------------------------------------
# AWS feature 7 becomes two unrelated things on OCI, and conflating them is a
# real trap:
#   - Pod-to-OCI identity is OKE Workload Identity, which needs NO OIDC
#     provider registration at all, only cluster_type = "enhanced" above.
#   - The OIDC *discovery* endpoint below exists so that AWS or GCP STS can
#     validate an OKE pod's service-account token - i.e. it is for OKE ->
#     other cloud, not OKE -> OCI. It is kept enabled because it is a
#     cluster-level setting this module owns and because it is the only clean
#     path for a pod that must still reach an un-migrated S3 bucket during
#     cutover (identity-model.md section 5, Option C).
variable "oidc_discovery_enabled" {
  description = "Publish the cluster's OIDC discovery document. Needed only for OKE-to-AWS/GCP federation during migration; NOT needed for OKE Workload Identity."
  type        = bool
  default     = true
}
