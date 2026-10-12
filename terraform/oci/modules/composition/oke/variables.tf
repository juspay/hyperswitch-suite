# oke - input surface. Ported from terraform/aws/modules/composition/eks.

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

# DIVERGENCE (new input, no AWS analogue): every OCI resource is
# compartment-scoped and the compartment must be named explicitly.
variable "compartment_id" {
  description = "OCID of the compartment the cluster, node pools and NSGs are created in. First cut uses one flat compartment for the whole environment."
  type        = string

  validation {
    condition     = startswith(var.compartment_id, "ocid1.compartment.") || startswith(var.compartment_id, "ocid1.tenancy.")
    error_message = "compartment_id must be a compartment or tenancy OCID."
  }
}

# OPTIONAL, deliberately: this module creates no IAM resources, and the AD
# lookup falls back to `compartment_id` when the tenancy is unknown (verified
# working in ap-mumbai-1). Making this required would put a tenancy OCID in
# every root.hcl for no gain.
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

# DIVERGENCE (new input, no AWS analogue): OKE Workload Identity - the pod
# identity mechanism this programme depends on - is available on ENHANCED
# clusters only. Defaulting to basic would silently make the whole identity
# model unimplementable, so the default is "enhanced".
variable "cluster_type" {
  description = "OKE cluster tier. Must be 'enhanced': OKE Workload Identity (the pod-identity mechanism this programme depends on) is available on enhanced clusters only."
  type        = string
  default     = "enhanced"

  # Restricted to "enhanced" on purpose: "basic" silently removes Workload
  # Identity and breaks all twelve identity-bearing application modules with no
  # plan-time signal. Relaxing this is an oracle-gate change, not a per-env knob.
  validation {
    condition     = lower(var.cluster_type) == "enhanced"
    error_message = "cluster_type must be 'enhanced'. OKE Workload Identity - the IRSA equivalent every application module in this programme is written against (docs/multi-cloud-parity/oci/identity-model.md) - is available on enhanced clusters only. Oracle, verbatim: \"You can only use workload identities to grant access to OCI resources when using enhanced clusters.\""
  }
}

# DIVERGENCE. On OCI the default is Flannel (overlay); VCN-native pod
# networking (`npn`) has to be asked for. `npn` is the parity choice - pods get
# a real, VCN-routable IP, which makes per-pod NSGs possible.
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

# Control-plane endpoint exposure. OKE has no first-class cluster-API allow-list:
# AWS's cluster_endpoint_public_access_cidrs and its VPN security-group rule
# both become ingress rules on the endpoint NSG - they MERGE into one list.

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

# Network - supplied by composition/vpc-network, never created here.

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

# GAP: with cni_type = 'npn' every pod consumes an IP from a real subnet. If
# vpc-network does not publish a dedicated pod tier, leaving this null makes
# pods share the worker subnet - legal, but node and pod addresses draw from the
# same pool, so the tier must be sized for nodes + (nodes x max_pods_per_node).
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

# DIVERGENCE. OKE has no tag convention: the cluster records one default
# service-LB subnet, and individual Services override it with the
# oci.oraclecloud.com/load-balancer-subnet annotation.
variable "preferred_load_balancer" {
  description = "Which LB subnet OKE picks by default for a Service of type LoadBalancer: 'internal' or 'public'."
  type        = string
  default     = "internal"

  validation {
    condition     = contains(["internal", "public"], var.preferred_load_balancer)
    error_message = "preferred_load_balancer must be 'internal' or 'public'."
  }
}

# Network Security Groups. By default the registry module creates the OKE NSGs
# and populates them with Oracle's baseline rules. `security-rules` adds its
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

# Node pools ("node pool" is OCI's term for a node group). TWO GAPS ARE
# ENCODED IN THIS TYPE - read them before adding a pool:
#
# 1. ONE SHAPE PER POOL. `oci_containerengine_node_pool` takes exactly one
#    `node_shape`, so express one AWS group with N candidate instance types as
#    N narrower pools, sharing labels and placement.
#
# 2. NO COMPUTE-LAYER MIN/MAX. The resource has ONLY `size` - no min_size or
#    max_size argument at all. `min_size`/`max_size` below are therefore NOT
#    enforced by this module or by OCI; they are carried purely so
#    oke-kubernetes-resources can render the Cluster Autoscaler's
#    `--nodes=<min>:<max>:<pool-OCID>` flags from the
#    node_pool_autoscaler_bounds output. If the autoscaler is unhealthy,
#    nothing pulls the pool back inside those bounds.
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

    # image_type "oke" lets Oracle resolve the current OKE image for the shape
    # and Kubernetes version; "custom" requires image_id.
    image_type = optional(string, "oke")
    image_id   = optional(string)

    # Fault domain NAMES, not availability domains and not ordinals. EMPTY IS
    # THE INTENDED VALUE: it resolves to every fault domain the region actually
    # publishes, via data.oci_identity_fault_domains. Set it only to pin a pool
    # to a subset, and only to names the data source returns.
    #
    # DO NOT write the short "FD-1" form - it is the registry module's internal
    # virtual-node-pool placeholder, never translated on the managed node-pool
    # path, and the OKE API rejects it (400-InvalidParameter). This default used
    # to be that list and it failed a real apply. Values are checked against the
    # live data source in main.tf's terraform_data.validate.
    fault_domains = optional(list(string), [])

    node_labels       = optional(map(string), {})
    max_pods_per_node = optional(number, 31)
    subnet_id         = optional(string)
    # Additive: concatenated with the managed worker NSG, not a replacement.
    nsg_ids = optional(list(string), [])
    # NOTE: pod NSGs are deliberately module-level only (additional_pod_nsg_ids).
    # A per-pool pod_nsg_ids key REPLACES rather than extends the managed pod
    # NSG in the registry module, which would silently detach the baseline pod
    # rules.
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

  # NOTE: there is deliberately no `validation` block for fault_domains here -
  # a variable validation cannot read a data source. The check lives in
  # main.tf's terraform_data.validate, against local.region_fault_domains.
}

# Boot/block volumes are encrypted at rest by default on OCI, so there is no
# `encrypted = true` to port - the AWS setting has no counterpart.
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

# Add-ons. On OKE the CNI and kube-proxy are bootstrapped by the service at
# node-join time and are not user-managed addons, so there is no
# before/after-nodes ordering. The Block Volume and File Storage CSI drivers
# authenticate as the OKE-managed control plane, so the EBS/EFS CSI IRSA roles
# disappear with no loss of capability.
variable "cluster_addons" {
  description = "OKE cluster add-ons, keyed by add-on name (e.g. CertManager, OracleDatabaseOperator). No before/after-nodes ordering exists or is needed - CNI and kube-proxy are service-managed."
  type        = any
  default     = {}
}

variable "cluster_kms_key_id" {
  description = "OCID of a Vault key used as the master encryption key for Kubernetes Secrets. GAP: setting this alone is not sufficient - because create_iam_resources is false (see main.tf), the dynamic group and 'use keys' policy that let the cluster reach the key must be created by the phase-0 IAM/compartment bootstrap. See eks.md gap 4.1."
  type        = string
  default     = null
}

# SSH key for node access. The registry module accepts an existing public key
# only - it neither generates nor persists one - so the two resources are added
# directly in ssh-key.tf, targeting OCI Vault.
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

# Cross-account administration - NOT IMPLEMENTED, GATE PENDING. OCI has no
# AssumeRole-across-accounts primitive; the replacement is an oracle-gate
# decision between OIDC federation and a same-tenancy dynamic group. Kept as
# named-but-unimplemented inputs so the gap stays visible rather than silently
# dropped; the validation makes turning it on a hard error.
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

# OIDC. AWS feature 7 becomes two unrelated things on OCI, and conflating them
# is a real trap: pod-to-OCI identity is OKE Workload Identity (needs NO OIDC
# registration, only cluster_type = "enhanced"); the OIDC discovery endpoint
# exists so AWS/GCP STS can validate an OKE pod's token - OKE -> other cloud,
# for migration cutover.
variable "oidc_discovery_enabled" {
  description = "Publish the cluster's OIDC discovery document. Needed only for OKE-to-AWS/GCP federation during migration; NOT needed for OKE Workload Identity."
  type        = bool
  default     = true
}
