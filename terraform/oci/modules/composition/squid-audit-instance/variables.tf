# =============================================================================
# squid-audit-instance - ONE standalone audit instance for the hardened Squid
# image, out of the pool
# =============================================================================
# This is IaC AUTHORING ONLY. Do not plan/apply. It is NOT the squid-proxy
# composition module (which creates an instance POOL + NLB + allowlist buckets).
# The security-team audit workflow (docs/hardening/oci-envoy-squid-hardening-workplan.md
# §6 step 3) launches ONE standalone instance from each freshly-built hardened
# image, runs the W1 baseline through Run Command, and terminates it after. This
# module is that single, disposable instance.
#
# Deliberately minimal, matching the envoy-audit-instance module 1:1 (so the
# two review boxes do not drift) and the envoy-proxy/failed-open contract:
#   - image_id is REQUIRED with no default and no PLACEHOLDER fallback.
#   - ssh_public_key is REQUIRED (the security team's dedicated key).
#   - No public IP: assign_public_ip = false per-VNIC + the management tier's
#     subnet-level prohibit_public_ip_on_vnic = true.
#   - preserve_boot_volume = false so terminate-after-audit removes the volume.

variable "compartment_id" {
  description = "OCID of the compartment the audit instance is created in. Same flat compartment contract as every other OCI unit."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, integ, sandbox, prod), used in the display name and freeform tags."
  type        = string
}

variable "project_name" {
  description = "Project name, used in the display name and freeform tags."
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "OCI region identifier, e.g. ap-mumbai-1. Informational - the provider carries the region - but rendered into the audit notes."
  type        = string
}

variable "availability_domain" {
  description = "Availability domain the audit instance is created in. Null resolves the first AD for the compartment from a data source. ap-mumbai-1 is a single-AD region, so this is a formality."
  type        = string
  default     = null
}

variable "fault_domain" {
  description = "Fault domain the instance is created in. Null lets OCI place it on best-effort."
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Freeform tags merged over the module's own set. The AWS tags_all analogue."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags (namespace.key = value). Passed straight through because they require a tag namespace this module does not own."
  type        = map(string)
  default     = {}
}

# =============================================================================
# Network
# =============================================================================

variable "vcn_id" {
  description = "OCID of the VCN. Needed only to create this module's NSG."
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet the audit instance's primary VNIC lands in. This is vpc-network's `management` tier - the SSH-reachable / jump-host tier, which is PRIVATE (prohibit_public_ip_on_vnic = true). The security team reaches the instance over the VPN by its private IP."
  type        = string
}

variable "create_nsg" {
  description = "Whether this module creates its own Network Security Group with an ingress rule permitting tcp:22 from the VPN/office source CIDRs ONLY. NSGs, never security lists (network-security-model.md section 5, Option A). Unlike the pooled squid-proxy module whose NSG stays empty and is filled by security-rules, this audit box writes its own inline SSH rule - it is self-contained and not part of the cross-unit NSG graph."
  type        = bool
  default     = true
}

variable "additional_nsg_ids" {
  description = "Extra NSG OCIDs to attach to the instance's primary VNIC, on top of this module's own. Capped by OCI at 5 NSGs per VNIC, not increasable."
  type        = list(string)
  default     = []
}

variable "vpn_source_cidrs" {
  description = "CIDR blocks that may reach SSH (tcp:22) on this audit instance. Required, no default - this is the whole security boundary of the box. Supply the repo's existing VPN + office ranges (values.ip_list.vpn_cidr_blocks + values.ip_list.office_ips)."
  type        = list(string)
}

# =============================================================================
# Compute - image, shape
# =============================================================================

variable "image_id" {
  description = <<-EOT
    OCID of the hardened custom image the audit instance boots from - the
    Packer-built hardened Ubuntu 24.04 squid image.

    REQUIRED with NO default and NO PLACEHOLDER fallback, exactly like
    squid-proxy's image_id. Fed from the SAME values.custom_images.squid the
    pool unit reads, so when the build produces a real OCID and it lands in
    values, this audit unit picks it up automatically.
  EOT
  type        = string
}

variable "shape" {
  description = "Compute shape for the audit instance. A flexible shape (VM.Standard.E4.Flex / E5.Flex) also needs shape_ocpus and shape_memory_in_gbs."
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "shape_ocpus" {
  description = "OCPUs for the flexible shape. One OCPU is two vCPUs."
  type        = number
  default     = 1
}

variable "shape_memory_in_gbs" {
  description = "Memory in GB for the flexible shape."
  type        = number
  default     = 8
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size in GB. Minimum 50 on OCI."
  type        = number
  default     = 50
}

variable "boot_volume_kms_key_id" {
  description = "Customer-managed KMS key for the boot volume. Null uses Oracle-managed encryption."
  type        = string
  default     = null
}

variable "disable_legacy_imds_endpoints" {
  description = "Disables the IMDSv1 (/opc/v1) endpoints, leaving only the token-gated v2 endpoint. Defaults true - hardened by default."
  type        = bool
  default     = true
}

variable "preserve_boot_volume" {
  description = "Whether the boot volume survives instance termination. false (the default and the fixed opinion) so the terminate-after-audit lifecycle actually removes the boot volume. This is a disposable review box."
  type        = bool
  default     = false
}

# =============================================================================
# SSH + boot-time hardening (the secreview-style review-user pattern)
# =============================================================================

variable "ssh_public_key" {
  description = "The security team's DEDICATED OpenSSH public key, authorized on the audit instance for a non-root review user (see userdata). REQUIRED - passed from values.security_team.ssh_public_key and supplied by InfoSec at apply time. No key is ever baked into the module or the image."
  type        = string
}

variable "metadata" {
  description = "Additional instance metadata (cloud-init keys and free-form values) merged over the module's own. `user_data` and `ssh_authorized_keys` are set by this module and will be overwritten if supplied here."
  type        = map(string)
  default     = {}
}