# =============================================================================
# envoy-audit-instance - ONE standalone audit instance for the hardened Envoy
# image, out of the pool
# =============================================================================
# This is IaC AUTHORING ONLY. Do not plan/apply. It is NOT the envoy-proxy
# composition module (which creates an instance POOL + load balancer). The
# security-team audit workflow (docs/hardening/oci-envoy-squid-hardening-workplan.md
# §6 step 3) launches ONE standalone instance from each freshly-built hardened
# image, runs the W1 baseline through Run Command, and terminates it after. This
# module is that single, disposable instance.
#
# It deliberately does NOT inherit envoy-proxy's pool/autoscaling/NLB/storage/
# break-glass/tls surface - none of those exist for a short-lived audit box.
# What it keeps from the envoy-proxy and bastion-host idioms:
#   - image_id is REQUIRED with no default and no PLACEHOLDER fallback, so a
#     plan fails loud if the build has not produced the hardened image OCID yet
#     (the SAME correctness contract envoy-proxy carries - vm-tier-and-images.md
#     section 2).
#   - ssh_public_key is REQUIRED (the security team's dedicated key), matching
#     the bastion-host pattern of a key coming in at apply time.
#   - prohibit a public IP (per-VNIC assign_public_ip = false + the management
#     subnet's own subnet-level prohibit_public_ip_on_vnic = true), so the
#     security team reaches it over the VPN by private IP only.
#   - preserve_boot_volume = false so the terminate-after-audit lifecycle
#     actually removes the boot volume instead of stranding it.

# =============================================================================
# Identity and placement
# =============================================================================

variable "compartment_id" {
  description = "OCID of the compartment the audit instance is created in. Same flat compartment contract as every other OCI unit (oci/identity-model.md)."
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
  description = <<-EOT
    Availability domain the audit instance is created in. Null resolves the
    first AD for the compartment from a data source. ap-mumbai-1 is a
    SINGLE-AD region, so this is a formality here - the same single value the
    envoy-proxy and bastion-host modules resolve.
  EOT
  type        = string
  default     = null
}

variable "fault_domain" {
  description = "Fault domain the instance is created in. Null lets OCI place it on best-effort. Single AD means this is the only availability lever."
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
  description = <<-EOT
    Whether this module creates its own Network Security Group with an ingress
    rule permitting tcp:22 from the VPN/office source CIDRs ONLY.
    NSGs, never security lists - the binding decision in oci/network-security-model.md
    section 5 (Option A). Unlike the pooled envoy-proxy module (whose NSG stays
    EMPTY and is filled by the last-phase security-rules unit), this audit
    module writes its OWN SSH ingress rule inline: it is a self-contained
    disposable host reached over the VPN, not a member of the cross-unit NSG
    graph, so it should not reserve a slot in the security-rules fan-in it is
    not a part of.
  EOT
  type        = bool
  default     = true
}

variable "additional_nsg_ids" {
  description = "Extra NSG OCIDs to attach to the instance's primary VNIC, on top of this module's own. Capped by OCI at 5 NSGs per VNIC, not increasable."
  type        = list(string)
  default     = []
}

# The source CIDRs that may reach tcp:22 - the VPN and office ranges the repo
# already defines (values.ip_list.vpn_cidr_blocks + office_ips in the live OCI
# stack, the same list security-rules and bastion-host consume). Required, so a
# plan fails loud if the stack has not supplied the real ranges - identical to
# the image_id contract.
variable "vpn_source_cidrs" {
  description = "CIDR blocks that may reach SSH (tcp:22) on this audit instance. Required, no default: this is the whole security boundary of the box, so an empty or absent list must fail at plan time rather than produce a box nobody reviewed the exposure of. Supply the repo's existing VPN + office ranges (values.ip_list.vpn_cidr_blocks + values.ip_list.office_ips)."
  type        = list(string)
}

# =============================================================================
# Compute - image, shape
# =============================================================================

variable "image_id" {
  description = <<-EOT
    OCID of the hardened custom image the audit instance boots from - the
    Packer-built UBUNTU 24.04 hardened envoy image.

    REQUIRED with NO default and NO PLACEHOLDER fallback, exactly like
    envoy-proxy's image_id: if the build has not produced the image OCID, this
    unit fails loud at plan time rather than booting a wrong/placeholder
    artifact. It is fed from the SAME values.custom_images.envoy the pool unit
    reads, so when the build produces a real OCID and it lands in values, this
    audit unit picks it up automatically.

    Taken directly as an OCID rather than derived from a data source - OCI has
    no image-family / newest-in-family concept to derive on.
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
  description = "Customer-managed KMS key for the boot volume. Null uses Oracle-managed encryption, the documented default posture."
  type        = string
  default     = null
}

variable "disable_legacy_imds_endpoints" {
  description = "Disables the IMDSv1 (/opc/v1) endpoints, leaving only the token-gated v2 endpoint. The analogue of AWS's metadata_options.http_tokens = \"required\". Defaults true - hardened by default."
  type        = bool
  default     = true
}

variable "preserve_boot_volume" {
  description = <<-EOT
    Whether the boot volume survives instance termination. false (the default
    and the fixed opinion here) so the terminate-after-audit lifecycle
    (workplan §6 step 3) actually removes the boot volume instead of stranding
    and silently billing it. This is a disposable review box, not a fleet member
    whose boot volume is a rollback path.
  EOT
  type        = bool
  default     = false
}

# =============================================================================
# SSH + boot-time hardening (the secreview-style review-user pattern)
# =============================================================================

variable "ssh_public_key" {
  description = <<-EOT
    The security team's DEDICATED OpenSSH public key, authorized on the audit
    instance for a non-root review user (see userdata). REQUIRED - it is passed
    from values.security_team.ssh_public_key and supplied by InfoSec at apply
    time. No key is ever baked into the module or the image; this is the single
    entry point for who may log in.
  EOT
  type        = string
}

variable "metadata" {
  description = "Additional instance metadata (cloud-init keys and free-form values) merged over the module's own. `user_data` and `ssh_authorized_keys` are set by this module and will be overwritten if supplied here."
  type        = map(string)
  default     = {}
}