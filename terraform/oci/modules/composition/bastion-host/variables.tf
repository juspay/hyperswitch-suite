variable "compartment_id" {
  description = "OCID of the compartment every resource in this module is created in. Replaces the implicit AWS account scope; a flat compartment is the deliberate first-cut simplification (prerequisite P5, oci/identity-model.md)."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, integ, sandbox, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name, used in resource naming and freeform tags"
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "OCI region identifier, e.g. ap-mumbai-1. Used verbatim in the rendered connection guide's CLI commands, so it must be the real region, not a label."
  type        = string
}

variable "availability_domain" {
  description = "Availability domain the jump instance is created in. Null means \"the first AD returned for this compartment\". ap-mumbai-1 is single-AD; a single instance has no availability story beyond the fault domain it lands in anyway."
  type        = string
  default     = null
}

variable "fault_domain" {
  description = "Fault domain within the availability domain. Null lets OCI choose. Unlike the pooled proxy modules there is nothing to spread here - one instance is in one fault domain, and that is the whole availability posture, same as the AWS single-EC2-instance original."
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

variable "vcn_id" {
  description = "OCID of the VCN. Needed only to create this module's NSG."
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet the jump instance lands in. This is vpc-network's `management` tier. The OCI Bastion's private endpoint is placed in the same subnet by default (see bastion_target_subnet_id)."
  type        = string
}

variable "bastion_target_subnet_id" {
  description = "OCID of the subnet the OCI Bastion service places its private endpoint in - oci_bastion_bastion.target_subnet_id. Null uses subnet_id. The bastion can only reach resources whose VNICs it can route to, so this is normally the same subnet as the jump instance."
  type        = string
  default     = null
}

variable "assign_public_ip" {
  description = "Whether the jump instance gets a public IP. FALSE, and it should stay false: the AWS original sets associate_public_ip_address = false and the whole point of the Bastion service in front is that the host needs no public address. Correction C7 (2026-09-04) made vpc-network's `management` tier private (prohibit_public_ip_on_vnic = true) on exactly this reasoning, so the subnet now enforces it too and setting this true against that tier will be rejected at apply time rather than quietly honoured. Left as a variable because the module must remain usable in a subnet that does permit public IPs."
  type        = bool
  default     = false
}

variable "create_nsg" {
  description = <<-EOT
    Whether this module creates its own Network Security Group.

    NSGs, never security lists - oci/network-security-model.md section 5,
    Option A. Created EMPTY: catalog/units/oci/security-rules, in the last
    stack phase, writes the rules by reading nsg_id from this module's outputs.

    THE ONE THING WHOEVER WRITES THOSE RULES MUST KNOW, and it is the single
    most load-bearing finding on this module's check sheet:
    "match AWS's zero-ingress security group" IS NOT AN ACHIEVABLE
    INSTRUCTION ON OCI. Every OCI Bastion session type - Managed SSH, SSH Port
    Forwarding and Dynamic (SOCKS5) Port Forwarding - requires an inbound rule
    on the target allowing traffic from the bastion's private endpoint IP on
    the target port. SSM Session Manager needs zero inbound rules under any
    configuration because the SSM Agent only ever makes outbound calls.
    bastion_private_endpoint_ip is exported for exactly this rule.
  EOT
  type        = bool
  default     = true
}

variable "additional_nsg_ids" {
  description = "Extra NSG OCIDs to attach to the jump instance's primary VNIC. Capped by OCI at 5 NSGs per VNIC, not increasable."
  type        = list(string)
  default     = []
}

variable "image_id" {
  description = <<-EOT
    OCID of the image the jump instance boots from.

    Unlike envoy-proxy and squid-proxy, this does NOT need a Packer-built
    custom image: the AWS original boots a stock Amazon Linux 2023 AMI and
    installs nothing, doing its hardening in userdata. Any OCI platform image
    (Oracle Linux, Ubuntu) works the same way here, and image_id is taken
    directly rather than looked up so the boot artefact is pinned and
    reproducible rather than drifting with Oracle's platform-image refreshes.

    One caveat that IS image-dependent: OCI Bastion's Managed SSH session type
    requires the Oracle Cloud Agent's Bastion plugin on the target. This module
    deliberately targets PORT_FORWARDING sessions instead (see the connection
    guide and check sheet §4), which are agentless, so the plugin is enabled
    below as a convenience rather than a requirement.
  EOT
  type        = string
}

variable "shape" {
  description = "Compute shape for the jump instance. A flexible shape also needs shape_ocpus and shape_memory_in_gbs. A bastion forwards ports; it does not need to be large."
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "shape_ocpus" {
  description = "OCPUs, for flexible shapes only."
  type        = number
  default     = 1
}

variable "shape_memory_in_gbs" {
  description = "Memory in GB, for flexible shapes only."
  type        = number
  default     = 8
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size in GB. Minimum 50 on OCI."
  type        = number
  default     = 50
}

variable "boot_volume_kms_key_id" {
  description = "Customer-managed KMS key for the boot volume. Null uses Oracle-managed encryption, the mapping for the AWS module's root_block_device.encrypted = true. Default-encrypted behaviour is Tier 2 pending confirmation (check sheet open question 5)."
  type        = string
  default     = null
}

variable "disable_legacy_imds_endpoints" {
  description = "Disables the IMDSv1 (/opc/v1) metadata endpoints, leaving only the token-gated v2 endpoint."
  type        = bool
  default     = true
}

variable "ssh_public_keys" {
  description = <<-EOT
    SSH public keys authorized on the jump instance.

    THIS LIST IS NOT OPTIONAL IN PRACTICE, and that is itself the port's
    headline regression. The AWS original needs no key of any kind, ever - SSM
    Session Manager is keyless and IAM-authenticated. Every OCI Bastion session
    requires an SSH keypair (key_details.public_key_content is a REQUIRED
    argument on oci_bastion_session), and a PORT_FORWARDING session forwards to
    the instance's own sshd, which must already trust the operator's key. See
    check sheet §3 item 2 and §4.
  EOT
  type        = list(string)
  default     = []
}

variable "metadata" {
  description = "Additional instance metadata merged over the module's own. `user_data` and `ssh_authorized_keys` are set by this module and will be overwritten if supplied here."
  type        = map(string)
  default     = {}
}

variable "user_data" {
  description = "cloud-init user-data. Null renders templates/userdata.sh, whose CONTENT ports from the AWS original with no logic changes - disable password authentication, disable root login - because cloud-init on OCI behaves identically to an AWS launch template's user_data, read from http://169.254.169.254/opc/v2/instance/metadata/. Only the templating glue around it changed."
  type        = string
  default     = null
}

variable "enable_oracle_cloud_agent_bastion_plugin" {
  description = "Enables the Oracle Cloud Agent's Bastion plugin on the instance. Required only for Managed SSH sessions, which this module deliberately does not use - PORT_FORWARDING is the correct session type for a fixed, known jump target (check sheet §4). Enabled anyway so an operator who needs Managed SSH is not blocked by a reboot."
  type        = bool
  default     = true
}

variable "create_bastion" {
  description = "Whether this module creates the OCI Bastion. False when a shared, environment-wide bastion already exists and this module only contributes the jump instance behind it."
  type        = bool
  default     = true
}

variable "bastion_client_cidr_allow_list" {
  description = <<-EOT
    CIDR blocks permitted to CALL the Bastion control plane to create a
    session - oci_bastion_bastion.client_cidr_block_allow_list.

    GENUINELY NEW SURFACE, not a port of anything. AWS gates Session Manager
    access on IAM alone and has no CIDR-shaped control over who may start a
    session. This is an additional, OCI-specific narrowing on top of IAM, so it
    is exposed rather than hardcoded.

    Defaults to 0.0.0.0/0 - which sounds alarming and is not the whole picture:
    it means "IAM alone decides", i.e. exactly AWS's posture, no weaker. Narrow
    it to the office/VPN ranges in root.hcl to get a control AWS cannot offer.
  EOT
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "bastion_max_session_ttl_seconds" {
  description = <<-EOT
    Bastion-wide cap on how long any single session may live -
    oci_bastion_bastion.max_session_ttl_in_seconds.

    PARTIAL (check sheet feature 5). This maps to AWS's `maxSessionDuration`
    session preference in spirit, but NOT to `idleSessionTimeout`: OCI's field
    is a session-LIFETIME cap, not an idle timer, and no idle-specific control
    was found. A session held open and unused is not reaped by this.

    Commonly cited bounds are 1800-10800 seconds, from secondary sources only -
    Oracle's own API reference page was not retrieved (check sheet open
    question 2). 10800 is the conservative choice: if the real maximum is
    lower the API rejects it loudly at apply time rather than silently
    truncating.
  EOT
  type        = number
  default     = 10800
}

variable "bastion_dns_proxy_status" {
  description = "Whether the bastion resolves DNS names on the client's behalf: ENABLED or DISABLED. ENABLED lets a port-forwarding session target a hostname (e.g. the database's private FQDN) rather than only an IP, which is what makes this useful as a tunnel to the OCI analogues of RDS and ElastiCache."
  type        = string
  default     = "ENABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.bastion_dns_proxy_status)
    error_message = "bastion_dns_proxy_status must be ENABLED or DISABLED."
  }
}

variable "log_retention_days" {
  description = "Retention in days for the host log. oci_logging_log.retention_duration is a straightforward analogue of aws_cloudwatch_log_group.retention_in_days."
  type        = number
  default     = 30
}

variable "enable_session_recording" {
  description = <<-EOT
    Whether to create the Object Storage bucket that a SELF-MANAGED session
    recorder writes to.

    NONE, twice over (check sheet features 3 and 4). This variable replaces
    BOTH of the AWS module's `ssm_cloudwatch_logging_enabled` and
    `ssm_s3_logging_enabled`, and the rename is deliberate rather than
    cosmetic: those two flags toggle a MANAGED capability, and there is no
    managed capability here to toggle.

    OCI has no mechanism that records session CONTENT - keystrokes and output -
    comparable to SSM's optional full transcript. OCI Audit records bastion
    CONTROL-PLANE calls only (CreateSession/DeleteSession: who, when, against
    which target). That is real and useful, and it is metadata, not a
    replayable transcript.

    So this flag creates a destination, and nothing that writes to it. The
    recorder itself - a script(1)-wrapped login shell or an auditd rule set,
    shipped through the same cloud-init path used for SSH hardening, forwarded
    here or to OCI Logging - is new, self-built, self-monitored tooling this
    platform does not currently run anywhere. It can silently stop working
    (disk full, misconfigured shipping) in a way a managed AWS checkbox is less
    likely to, so it needs a health check of its own.

    Adopting that pipeline is an oracle-gate item (check sheet §8 item 2, not
    consulted). The bucket is created honestly named and empty rather than
    pretending the capability exists.
  EOT
  type        = bool
  default     = false
}

variable "session_log_bucket_name" {
  description = "Name of the self-managed session-recording bucket. Null derives it from the name prefix."
  type        = string
  default     = null
}

variable "session_log_retention_days" {
  description = "Days before a session recording is deleted. The AWS module's S3 path uses a Glacier lifecycle; the ARCHIVE tier below is its counterpart, and this half of feature 4 IS full parity - only the thing being archived is the gap."
  type        = number
  default     = 365
}

variable "session_log_archive_after_days" {
  description = "Days before a session recording is moved to Archive storage. Null disables the transition."
  type        = number
  default     = 30
}

variable "bucket_kms_key_id" {
  description = "Customer-managed key for the session-recording bucket. Null uses Oracle-managed encryption."
  type        = string
  default     = null
}

variable "enable_migration_mode" {
  description = <<-EOT
    Temporary escape hatch granting remote command execution against the jump
    host, for one-off migration work. Meant to be turned back off.

    PARTIAL (check sheet feature 10), and the shortfall is specifically about
    Terraform, not about the cloud. OCI Run Command is the functional analogue
    of the AWS module's `ssm:SendCommand` grant - it explicitly works "even
    when the instance does not have SSH access or open inbound ports". But
    there is NO Terraform resource for it in oracle/oci 9.0.0: the permission
    is expressible (an IAM policy verb granted to the instance's dynamic
    group), the command content and invocation are API/CLI/Console-only.

    Consequence worth naming: the AWS module's `migration_mode_status` output
    exists so a `terraform plan` reminds someone that migration mode is still
    on. Here there is no resource to derive that from, so the output is
    recomputed from this variable alone - it tells you what was CONFIGURED, not
    what is live.

    This module therefore creates nothing when this is true. It only surfaces
    the flag in outputs, because the policy statement it would drive belongs to
    oci/identity-model.md's dynamic-group design, which has not landed.
  EOT
  type        = bool
  default     = false
}

variable "connection_targets" {
  description = <<-EOT
    Endpoints an operator tunnels to THROUGH this host, name -> {host, port}.
    Purely informational: rendered into the connection guide output.

    This exists because the module's reason to exist is being the one hop that
    can reach the agentless data-tier endpoints - the OCI analogues of RDS and
    ElastiCache - which cannot be reached by a broker directly. That reason
    survives the port to any cloud; only the broker changes.

    Populated at the LIVE/UNIT layer via dependency blocks, never resolved by
    this module itself - matching the GCP precedent exactly, where
    connection_targets is unit-level convenience wiring rather than a module
    input the module goes and looks up.
  EOT
  type = map(object({
    host        = string
    port        = number
    description = optional(string, "")
  }))
  default = {}
}
