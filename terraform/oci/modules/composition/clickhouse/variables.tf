# =============================================================================
# Identity and naming
# =============================================================================

variable "environment" {
  description = "Environment short name (dev, sandbox, prod)."
  type        = string
}

variable "project_name" {
  description = "Project name. Part of every resource name."
  type        = string
}

variable "compartment_id" {
  description = "OCID of the compartment every resource is created in. No AWS analogue."
  type        = string
}

variable "tenancy_ocid" {
  description = "Tenancy OCID. Required only when create_identity = true - a dynamic group is a tenancy-level object."
  type        = string
  default     = null
}

# =============================================================================
# Placement
# =============================================================================

variable "availability_domain" {
  description = <<-EOT
    Availability domain for every node. Null resolves the first AD via
    data.oci_identity_availability_domains. ap-mumbai-1 has exactly ONE, so a
    3-node Keeper quorum has no AZ-equivalent spread available.
  EOT
  type        = string
  default     = null
}

variable "fault_domains" {
  description = "Fault domain names to round-robin nodes across. Empty resolves all three via data.oci_identity_fault_domains."
  type        = list(string)
  default     = []
}

# =============================================================================
# Network
# =============================================================================

variable "vcn_id" {
  description = "OCID of the VCN. Needed only to create the module-owned NSGs."
  type        = string
}

variable "keeper_subnet_id" {
  description = "OCID of the subnet the Keeper VNICs land in. Normally vpc-network's subnets_by_tier[\"data-stack\"]."
  type        = string
}

variable "server_subnet_id" {
  description = "OCID of the subnet the server VNICs land in."
  type        = string
}

variable "load_balancer_subnet_id" {
  description = <<-EOT
    OCID of the subnet the internal load balancer lands in. SINGULAR, replacing
    AWS's alb_subnet_ids.

    AWS's variable carries a hard `length(...) >= 2` validation because an ALB
    requires subnets in two distinct AZs. An OCI Load Balancer does not: a single
    subnet deployment is valid. In a one-AD region that is not a convenience, it
    removes a hard blocker - the AWS rule, ported literally, could never be
    satisfied in ap-mumbai-1.

    Whether this should be the data-stack tier or a dedicated LB tier is check
    sheet open question 9.3, UNRESOLVED; data-stack is the working assumption.
  EOT
  type        = string
}

variable "create_nsg" {
  description = "Create the module-owned, deliberately empty Keeper and server NSGs. Rules are written by composition/security-rules."
  type        = bool
  default     = true
}

variable "additional_keeper_nsg_ids" {
  description = "Pre-existing NSG OCIDs to attach to Keeper VNICs in addition to the module-owned one."
  type        = list(string)
  default     = []
}

variable "additional_server_nsg_ids" {
  description = "Pre-existing NSG OCIDs to attach to server VNICs in addition to the module-owned one."
  type        = list(string)
  default     = []
}

variable "assign_private_dns_record" {
  description = "Register an internal DNS A record for each node VNIC."
  type        = bool
  default     = true
}

variable "keeper_reserved_ip_addresses" {
  description = <<-EOT
    Optional explicit IPv4 addresses for the Keepers' reserved private IPs, one
    per Keeper, inside keeper_subnet_id's CIDR.

    PIN THESE. The user-data templates substitute {{keeper_ips}} and
    {{server_ips}}, and on OCI those values cannot come from the reserved-IP
    objects without a dependency cycle - see locals.tf. Unpinned, the templates
    receive empty peer lists.
  EOT
  type        = list(string)
  default     = null
}

variable "server_reserved_ip_addresses" {
  description = "Optional explicit IPv4 addresses for the servers' reserved private IPs, one per server. Same pinning requirement as keeper_reserved_ip_addresses."
  type        = list(string)
  default     = null
}

# =============================================================================
# Keeper tier
# =============================================================================

variable "keeper_count" {
  description = "Number of ClickHouse Keeper nodes. AWS default 3. 0 uses an externally-provided Keeper cluster and creates no Keeper resources at all."
  type        = number
  default     = 3
}

variable "keeper_image_id" {
  description = "OCID of the custom image the Keepers boot from. Replaces keeper_ami_id. NO OCI IMAGE PIPELINE EXISTS YET (vm-tier-and-images.md section 4)."
  type        = string
  default     = null
}

variable "keeper_shape" {
  description = "Compute shape for the Keepers. Flexible shapes decouple OCPU/memory from the shape name, so keeper_instance_type becomes three arguments."
  type        = string
  default     = "VM.Standard.E5.Flex"
}

variable "keeper_ocpus" {
  description = "OCPUs per Keeper. One OCPU is one physical core (two vCPUs on x86 SMT shapes)."
  type        = number
  default     = 2
}

variable "keeper_memory_in_gbs" {
  description = "Memory per Keeper, GB."
  type        = number
  default     = 16
}

variable "keeper_boot_volume_size_in_gbs" {
  description = "Keeper boot volume size, GB. Replaces keeper_root_volume_size. Boot volume is deleted with the instance, matching AWS's delete_on_termination = true."
  type        = number
  default     = 100
}

variable "keeper_boot_volume_vpus_per_gb" {
  description = "Keeper boot volume VPUs per GB. Replaces keeper_root_volume_type."
  type        = number
  default     = 10
}

variable "keeper_data_volume_size_in_gbs" {
  description = "Keeper first data volume size, GB. Replaces keeper_data_volume_size."
  type        = number
  default     = 20
}

variable "keeper_data_volume_vpus_per_gb" {
  description = "Keeper first data volume VPUs per GB. Replaces keeper_data_volume_type ('gp3')."
  type        = number
  default     = 10
}

variable "keeper_data2_volume_size_in_gbs" {
  description = "Keeper second data volume size, GB. Replaces keeper_data2_volume_size. See storage.tf for why there are two."
  type        = number
  default     = 20
}

variable "keeper_data2_volume_vpus_per_gb" {
  description = "Keeper second data volume VPUs per GB. Replaces keeper_data2_volume_type."
  type        = number
  default     = 10
}

# =============================================================================
# Server tier
# =============================================================================

variable "server_count" {
  description = "Number of ClickHouse server (query) nodes. AWS default 2."
  type        = number
  default     = 2
}

variable "server_image_id" {
  description = "OCID of the custom image the servers boot from. Replaces server_ami_id. Same missing-pipeline caveat."
  type        = string
}

variable "server_shape" {
  description = "Compute shape for the servers. r7g.large (2 vCPU / 16 GB) maps to 2 OCPU / 16 GB here."
  type        = string
  default     = "VM.Standard.E5.Flex"
}

variable "server_ocpus" {
  description = "OCPUs per server."
  type        = number
  default     = 2
}

variable "server_memory_in_gbs" {
  description = "Memory per server, GB."
  type        = number
  default     = 32
}

variable "server_boot_volume_size_in_gbs" {
  description = "Server boot volume size, GB. Replaces server_root_volume_size."
  type        = number
  default     = 200
}

variable "server_boot_volume_vpus_per_gb" {
  description = "Server boot volume VPUs per GB. Replaces server_root_volume_type."
  type        = number
  default     = 10
}

variable "server_data_volume_size_in_gbs" {
  description = "Server first data volume size, GB. Replaces server_data_volume_size."
  type        = number
  default     = 20
}

variable "server_data_volume_vpus_per_gb" {
  description = "Server first data volume VPUs per GB. Replaces server_data_volume_type ('gp3')."
  type        = number
  default     = 10
}

variable "server_data2_volume_size_in_gbs" {
  description = "Server second data volume size, GB. Replaces server_data2_volume_size."
  type        = number
  default     = 20
}

variable "server_data2_volume_vpus_per_gb" {
  description = "Server second data volume VPUs per GB. Replaces server_data2_volume_type."
  type        = number
  default     = 10
}

# =============================================================================
# Storage
# =============================================================================

variable "data_volume_attachment_type" {
  description = <<-EOT
    "iscsi" (default) or "paravirtualized". See storage.tf - this default is a
    deliberate choice with a new failure mode behind it, and check sheet section
    8 item 4 makes it an oracle gate item.
  EOT
  type        = string
  default     = "iscsi"

  validation {
    condition     = contains(["paravirtualized", "iscsi"], var.data_volume_attachment_type)
    error_message = "data_volume_attachment_type must be \"paravirtualized\" or \"iscsi\"."
  }
}

variable "volume_kms_key_id" {
  description = "Optional Vault key OCID for boot and block volume encryption. Encryption is always on with an Oracle-managed key and cannot be disabled; this only swaps the key."
  type        = string
  default     = null
}

variable "prevent_data_volume_destroy" {
  description = <<-EOT
    Reserved for documentation only - Terraform forbids a variable in a
    `lifecycle` block, so `prevent_destroy = true` is HARDCODED on all four data
    volume classes in storage.tf, exactly as the AWS module hardcodes it.

    Recorded as a variable so the intent is visible in the input surface and so
    nobody adds one later believing it will work.
  EOT
  type        = bool
  default     = true
}

# =============================================================================
# Load balancer (check sheet feature 12, FULL - and section 4.5)
# =============================================================================

variable "clickhouse_port" {
  description = "ClickHouse HTTP port. Unchanged from AWS."
  type        = number
  default     = 8123
}

variable "load_balancer_shape" {
  description = "OCI Load Balancer shape. \"flexible\" with a bandwidth range is the modern equivalent of AWS's implicitly-scaled ALB."
  type        = string
  default     = "flexible"
}

variable "load_balancer_min_bandwidth_in_mbps" {
  description = "Minimum bandwidth for a flexible-shape load balancer. No AWS counterpart - an ALB has no customer-set capacity floor."
  type        = number
  default     = 10
}

variable "load_balancer_max_bandwidth_in_mbps" {
  description = "Maximum bandwidth for a flexible-shape load balancer. No AWS counterpart."
  type        = number
  default     = 100
}

variable "load_balancer_listeners" {
  description = <<-EOT
    Listeners on the internal load balancer. Replaces alb_listeners: same shape,
    with certificate_id (an OCI Certificates OCID) where AWS had certificate_arn.
  EOT
  type = list(object({
    name           = string
    port           = number
    protocol       = optional(string, "HTTP")
    certificate_id = optional(string)
  }))
  default = []
}

variable "health_check_path" {
  description = "Backend health check path. AWS uses /ping."
  type        = string
  default     = "/ping"
}

variable "health_check_interval_ms" {
  description = "Health check interval, milliseconds."
  type        = number
  default     = 10000
}

variable "health_check_timeout_ms" {
  description = "Health check timeout, milliseconds."
  type        = number
  default     = 3000
}

variable "health_check_retries" {
  description = "Health check retries before a backend is marked unhealthy."
  type        = number
  default     = 3
}

variable "backend_set_policy" {
  description = "Load balancing policy: ROUND_ROBIN, LEAST_CONNECTIONS or IP_HASH."
  type        = string
  default     = "ROUND_ROBIN"
}

# =============================================================================
# Bootstrap
# =============================================================================

variable "keeper_user_data_template" {
  description = <<-EOT
    Keeper user-data template. {{keeper_ips}} and {{server_ips}} are substituted
    with the peer address lists before the instance boots - the same mechanism the
    AWS module uses, fed from reserved private IPs instead of ENIs.

    READ locals.tf: on OCI those substitutions only carry real values when
    keeper_reserved_ip_addresses / server_reserved_ip_addresses are PINNED.
  EOT
  type        = string
  default     = null
}

variable "server_user_data_template" {
  description = "Server user-data template. Same {{keeper_ips}} / {{server_ips}} substitution and the same pinning requirement."
  type        = string
  default     = null
}

variable "keeper_startup_delay_seconds" {
  description = "Seconds to wait after the Keepers exist before any server launches. The AWS module has no such gate; ClickHouse servers that start before the Keeper quorum forms fail their first coordination round."
  type        = number
  default     = 120
}

# =============================================================================
# Hardening and agents
# =============================================================================

variable "are_legacy_imds_endpoints_disabled" {
  description = "Disable the legacy /v1 metadata endpoints - the equivalent of metadata_options.http_tokens = \"required\"."
  type        = bool
  default     = true
}

variable "enable_monitoring_plugin" {
  description = "Enable the Oracle Cloud Agent Compute Instance Monitoring plugin."
  type        = bool
  default     = true
}

variable "recovery_action" {
  description = "Instance availability recovery_action: RESTORE_INSTANCE or STOP_INSTANCE."
  type        = string
  default     = "RESTORE_INSTANCE"
}

# =============================================================================
# SSH
# =============================================================================

variable "create_key_pair" {
  description = "Generate an SSH key pair for the fleet."
  type        = bool
  default     = true
}

variable "public_key" {
  description = "Caller-supplied SSH public key. When null and create_key_pair is true the module generates one."
  type        = string
  default     = null
}

variable "key_name" {
  description = "Logical key-pair name. OCI has no key-pair object; keys are instance metadata."
  type        = string
  default     = null
}

variable "vault_secret" {
  description = "Vault + KMS key the generated SSH private key is escrowed into. Replaces the AWS aws_ssm_parameter SecureString. Inert while either is null."
  type = object({
    vault_id    = optional(string)
    key_id      = optional(string)
    secret_name = optional(string)
  })
  default = null
}

# =============================================================================
# Identity
# =============================================================================

variable "create_identity" {
  description = "Create the dynamic group + policy giving the nodes their instance-principal identity. Requires tenancy_ocid."
  type        = bool
  default     = false
}

variable "identity_matching_rule" {
  description = "Override the dynamic group matching rule. Null emits a compartment-scoped rule - see identity.tf."
  type        = string
  default     = null
}

variable "policy_statements" {
  description = <<-EOT
    Policy statements for the dynamic group. Empty emits a narrow default.

    This is the OCI counterpart of the AWS module's iam_inline_policies /
    iam_managed_policy_arns override pair - and unlike ../kafka and ../cassandra,
    the AWS original already expected callers to override its broad default. This
    module's default is the one that should actually be reviewed, not a copy of
    the other two.
  EOT
  type        = list(string)
  default     = []
}

# =============================================================================
# Tags
# =============================================================================

variable "freeform_tags" {
  description = "Additional freeform tags, merged over the module's own. The OCI analogue of the AWS `tags` variable."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags, passed through untouched."
  type        = map(string)
  default     = {}
}
