# =============================================================================
# Identity and naming
# =============================================================================

variable "environment" {
  description = "Environment short name (dev, sandbox, prod). Part of every resource name."
  type        = string
}

variable "project_name" {
  description = "Project name. Part of every resource name."
  type        = string
}

variable "compartment_id" {
  description = <<-EOT
    OCID of the compartment every resource in this module is created in. No AWS
    analogue - on AWS the account plus the VPC supplied the scope implicitly.
  EOT
  type        = string
}

variable "tenancy_ocid" {
  description = <<-EOT
    Tenancy OCID. Required only when create_identity = true: an
    oci_identity_dynamic_group is a TENANCY-level object on OCI and cannot be
    created in a child compartment, unlike the AWS IAM role it replaces which
    was account-scoped but needed no explicit account reference.
  EOT
  type        = string
  default     = null
}

# =============================================================================
# Placement - see README "Availability domains and fault domains"
# =============================================================================

variable "availability_domain" {
  description = <<-EOT
    Availability domain name to place every broker and controller in. Leave null
    to resolve the first AD in the compartment via
    data.oci_identity_availability_domains.

    ap-mumbai-1 has exactly ONE availability domain (only us-ashburn-1,
    us-phoenix-1, uk-london-1, eu-frankfurt-1 and us-chicago-1 have three), so
    there is nothing to spread across here and no AZ-equivalent HA available.
    Fault domains are the only in-region fault isolation - see var.fault_domains.
  EOT
  type        = string
  default     = null
}

variable "fault_domains" {
  description = <<-EOT
    Fault domain names to round-robin broker and controller instances across.
    Leave empty to resolve all fault domains in the chosen AD via
    data.oci_identity_fault_domains (always exactly three).

    This is the placement decision vpc-network.md explicitly declined to own:
    "AD/FD placement is the compute modules' job, not this one's". For a 3-node
    KRaft controller quorum the resulting placement is one controller per fault
    domain, which tolerates a rack/host failure but NOT a whole-AD event.
  EOT
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

variable "broker_subnet_id" {
  description = "OCID of the subnet the broker VNICs land in. Normally vpc-network's subnets_by_tier[\"data-stack\"]."
  type        = string
}

variable "controller_subnet_id" {
  description = "OCID of the subnet the controller VNICs land in. Normally the same data-stack subnet."
  type        = string
}

variable "create_nsg" {
  description = <<-EOT
    Create the module-owned, deliberately EMPTY broker and controller NSGs.

    Same contract as the AWS module's aws_security_group: this module owns the
    object, the security-last stack phase (composition/security-rules) writes the
    rules into it by reading broker_nsg_id / controller_nsg_id. Keeping the object
    here and the rules there is what breaks the dependency cycle between kafka and
    everything that talks to it.
  EOT
  type        = bool
  default     = true
}

variable "additional_broker_nsg_ids" {
  description = "Pre-existing NSG OCIDs to attach to broker VNICs in addition to the module-owned one."
  type        = list(string)
  default     = []
}

variable "additional_controller_nsg_ids" {
  description = "Pre-existing NSG OCIDs to attach to controller VNICs in addition to the module-owned one."
  type        = list(string)
  default     = []
}

variable "assign_private_dns_record" {
  description = "Register an internal DNS A record for each VNIC in the subnet's DNS zone."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Static addressing (SUBSTITUTE - check sheet feature 3, section 4.2)
# -----------------------------------------------------------------------------

variable "broker_reserved_ip_addresses" {
  description = <<-EOT
    Optional explicit IPv4 addresses for the brokers' reserved private IPs, one
    per broker, inside broker_subnet_id's CIDR. Leave null to let OCI allocate.

    The addresses are what KRaft's static voter list and every downstream
    producer/consumer's bootstrap string are built from, so pinning them makes
    the cluster's addressing reproducible from configuration rather than from
    whatever the subnet handed out first.
  EOT
  type        = list(string)
  default     = null
}

variable "controller_reserved_ip_addresses" {
  description = "Optional explicit IPv4 addresses for the controllers' reserved private IPs, one per controller."
  type        = list(string)
  default     = null
}

# =============================================================================
# Broker tier
# =============================================================================

variable "broker_count" {
  description = "Number of Kafka broker instances. AWS default is 3."
  type        = number
  default     = 3
}

variable "broker_image_id" {
  description = <<-EOT
    OCID of the custom image the brokers boot from. Replaces broker_ami_id.

    NO IMAGE BUILD PIPELINE EXISTS FOR OCI YET (see
    docs/multi-cloud-parity/oci/vm-tier-and-images.md section 4). The GCP port
    shipped PLACEHOLDER-kafka-broker into its stack and it is still there; do not
    repeat that here - land a real built image before the unit that consumes this
    is applied.
  EOT
  type        = string
}

variable "broker_shape" {
  description = <<-EOT
    Compute shape for the brokers. OCI flexible shapes decouple OCPU and memory
    from the shape name, which is why broker_ocpus / broker_memory_in_gbs exist
    where AWS had a single broker_instance_type. t4g.medium (2 vCPU / 4 GB,
    non-SMT Graviton) maps to 2 OCPU / 4 GB here.

    Which shape FAMILY (Ampere A1/A2.Flex vs x86 E4/E5.Flex) is a
    vm-tier-and-images.md decision, not this module's - it takes the family as a
    variable. Whether the chosen family is orderable in ap-mumbai-1 at the needed
    quota is check sheet open question 9.1, UNRESOLVED.
  EOT
  type        = string
  default     = "VM.Standard.E5.Flex"
}

variable "broker_ocpus" {
  description = "OCPUs per broker. One OCPU is one physical core (two vCPUs on x86 SMT shapes)."
  type        = number
  default     = 2
}

variable "broker_memory_in_gbs" {
  description = "Memory per broker, GB."
  type        = number
  default     = 16
}

variable "broker_boot_volume_size_in_gbs" {
  description = "Boot volume size per broker, GB. Replaces broker_root_volume_size. Minimum 50."
  type        = number
  default     = 50
}

variable "broker_boot_volume_vpus_per_gb" {
  description = <<-EOT
    Boot volume performance, in VPUs per GB. Replaces broker_root_volume_type
    ('gp3'): OCI sizes performance with a VPU tier rather than a volume-type
    string. 0 = Lower Cost, 10 = Balanced, 20 = Higher Performance,
    30-120 = Ultra High Performance.
  EOT
  type        = number
  default     = 10
}

variable "broker_data_volume_size_in_gbs" {
  description = "Dedicated data volume size per broker, GB. Replaces broker_data_volume_size."
  type        = number
  default     = 100
}

variable "broker_data_volume_vpus_per_gb" {
  description = "Data volume VPUs per GB. Replaces broker_data_volume_type ('gp3'). 10 = Balanced = 60 IOPS/GB."
  type        = number
  default     = 10
}

# =============================================================================
# Controller tier
# =============================================================================

variable "controller_count" {
  description = <<-EOT
    Number of KRaft controller instances.

    DELIBERATE DIVERGENCE FROM AWS, default 3 not 1. The AWS module creates
    exactly one aws_instance.controller with no count - a single point of failure
    for the metadata quorum even though KRaft supports N. The catalog unit calls
    that footprint "cost-optimized for passive/DR", so it may be deliberate rather
    than an oversight. Check sheet section 8 item 4 and open question 9.4:
    ORACLE GATE ITEM, NOT YET CONSULTED. Set to 1 to reproduce AWS exactly.
  EOT
  type        = number
  default     = 3
}

variable "controller_image_id" {
  description = "OCID of the custom image the controllers boot from. Replaces controller_ami_id. Same missing-pipeline caveat as broker_image_id."
  type        = string
}

variable "controller_shape" {
  description = "Compute shape for the controllers. See broker_shape."
  type        = string
  default     = "VM.Standard.E5.Flex"
}

variable "controller_ocpus" {
  description = "OCPUs per controller."
  type        = number
  default     = 1
}

variable "controller_memory_in_gbs" {
  description = "Memory per controller, GB."
  type        = number
  default     = 8
}

variable "controller_boot_volume_size_in_gbs" {
  description = "Boot volume size per controller, GB. Replaces controller_root_volume_size."
  type        = number
  default     = 50
}

variable "controller_boot_volume_vpus_per_gb" {
  description = "Controller boot volume VPUs per GB. Replaces controller_root_volume_type."
  type        = number
  default     = 10
}

variable "controller_metadata_volume_size_in_gbs" {
  description = "KRaft metadata log volume size per controller, GB. Replaces controller_metadata_volume_size."
  type        = number
  default     = 50
}

variable "controller_metadata_volume_vpus_per_gb" {
  description = "Controller metadata volume VPUs per GB. Replaces controller_metadata_volume_type."
  type        = number
  default     = 10
}

# =============================================================================
# Storage attachment
# =============================================================================

variable "data_volume_attachment_type" {
  description = <<-EOT
    "paravirtualized" or "iscsi".

    OCI offers exactly two attachment types where AWS's EBS attachment had one.
    Paravirtualized is zero-touch - the volume appears in the guest with no
    in-guest action, the way an EBS volume does - but Oracle documents it as
    lower and less consistent IOPS. iSCSI "can provide improved and more
    consistent IOPS" but the guest must register and log in to the target
    (`iscsiadm`) before the block device exists.

    Kafka defaults to PARAVIRTUALIZED, unlike cassandra and clickhouse in this
    same wave which default to iscsi: the check sheet calls for iSCSI where a
    gp3 IOPS floor is load-bearing (ClickHouse merges, Cassandra compaction) and
    does not call for it here. Set to "iscsi" if broker log-append latency turns
    out to need it, and read the iSCSI note in cassandra/storage.tf first - it is
    a new failure mode with no AWS precedent.
  EOT
  type        = string
  default     = "paravirtualized"

  validation {
    condition     = contains(["paravirtualized", "iscsi"], var.data_volume_attachment_type)
    error_message = "data_volume_attachment_type must be \"paravirtualized\" or \"iscsi\"."
  }
}

variable "volume_kms_key_id" {
  description = <<-EOT
    Optional Vault key OCID for boot and block volume encryption. Encryption at
    rest is ALWAYS on with an Oracle-managed key and cannot be disabled - stricter
    than AWS, where `encrypted = true` had to be set explicitly. This only swaps
    the key.
  EOT
  type        = string
  default     = null
}

# =============================================================================
# Bootstrap
# =============================================================================

variable "broker_user_data_override" {
  description = "Raw broker user_data. When null the module builds the same JSON blob the AWS module does."
  type        = string
  default     = null
}

variable "controller_user_data_override" {
  description = "Raw controller user_data. When null the module builds the same JSON blob the AWS module does."
  type        = string
  default     = null
}

variable "broker_extra_config" {
  description = "Contents of the `extraConf` field in the broker user-data JSON. Defaults to the AWS module's tuning block verbatim."
  type        = string
  default     = null
}

variable "controller_startup_delay_seconds" {
  description = <<-EOT
    Seconds to wait after the controllers exist before any broker launches.
    Straight port of the AWS module's time_sleep.wait_for_controller (180s):
    brokers that start before the controller quorum is formed fail their first
    metadata fetch.
  EOT
  type        = number
  default     = 180
}

# =============================================================================
# Instance hardening and agents
# =============================================================================

variable "are_legacy_imds_endpoints_disabled" {
  description = <<-EOT
    Disable the legacy /v1 instance metadata endpoints. The direct equivalent of
    the AWS module's metadata_options.http_tokens = "required": both force the
    token-gated metadata service. OCI's provider default is false, so this must be
    set explicitly, exactly as on AWS.
  EOT
  type        = bool
  default     = true
}

variable "enable_monitoring_plugin" {
  description = <<-EOT
    Enable the Oracle Cloud Agent "Compute Instance Monitoring" plugin - the
    equivalent of the AWS module's `monitoring = true` (EC2 detailed 1-minute
    CloudWatch metrics).
  EOT
  type        = bool
  default     = true
}

variable "recovery_action" {
  description = "Instance availability recovery_action: RESTORE_INSTANCE or STOP_INSTANCE."
  type        = string
  default     = "RESTORE_INSTANCE"
}

# =============================================================================
# SSH key pair and escrow
# =============================================================================

variable "create_key_pair" {
  description = "Generate an SSH key pair for the fleet. Same semantics as the AWS module."
  type        = bool
  default     = true
}

variable "public_key" {
  description = "Caller-supplied SSH public key. When null and create_key_pair is true, the module generates one with tls_private_key."
  type        = string
  default     = null
}

variable "key_name" {
  description = "Logical name for the key pair. OCI has no aws_key_pair object - keys are pushed through instance metadata - so this is a naming/label input only."
  type        = string
  default     = null
}

variable "vault_secret" {
  description = <<-EOT
    Where the generated SSH private key is escrowed. Replaces the AWS module's
    aws_ssm_parameter SecureString.

    OCI Vault Secrets are NOT a flat namespace like SSM Parameter Store: they
    require a pre-existing Vault and a pre-existing KMS key. When either is null
    nothing is written and the private key exists only in Terraform state, which
    makes the state backend's encryption load-bearing. Check sheet open question
    9.2 (which Vault) is UNRESOLVED; the dev root has vault_id = null today.
  EOT
  type = object({
    vault_id    = optional(string)
    key_id      = optional(string)
    secret_name = optional(string)
  })
  default = null
}

# =============================================================================
# Node identity (SUBSTITUTE - check sheet feature 6, section 4.3)
# =============================================================================

variable "create_identity" {
  description = <<-EOT
    Create the dynamic group + policy that give the instances their instance-
    principal identity, replacing the AWS IAM role + instance profile.

    There is no "attach this profile to this instance" step on OCI. An instance
    obtains credentials implicitly once it matches a dynamic group's matching rule
    and a policy grants that group permissions. Requires tenancy_ocid.
  EOT
  type        = bool
  default     = false
}

variable "policy_statements" {
  description = <<-EOT
    Policy statements granted to the dynamic group. When empty the module emits a
    deliberately NARROW default (read-only inspection of its own compartment's
    instances and VNICs, plus log ingestion).

    The AWS role this replaces grants ec2:* and autoscaling:* on Resource "*"
    plus sts:AssumeRole. That is not the security bar to match - the port is the
    narrowing opportunity, and copying it verbatim would be porting the plumbing
    instead of the model.
  EOT
  type        = list(string)
  default     = []
}

variable "identity_tag_value" {
  description = "Value of the `component` freeform tag the dynamic group matches on. Also the component tag on every resource."
  type        = string
  default     = "kafka"
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
  description = "Defined tags, passed through untouched. OCI has two tag namespaces where AWS has one; defined tags need a namespace this module does not own."
  type        = map(string)
  default     = {}
}

variable "identity_matching_rule" {
  description = <<-EOT
    Override the dynamic group's matching rule. When null the module emits
    `ALL {instance.compartment.id = '<compartment_id>'}`.

    OCI's rule grammar cannot match on a freeform tag - only on
    instance.compartment.id, instance.id, or a DEFINED tag
    (tag.<namespace>.<key>.value), and no tag namespace exists in this tenancy
    yet. The compartment-scoped default is therefore wider than the AWS instance
    profile it replaces. Supply a defined-tag rule here as soon as a namespace
    exists.
  EOT
  type        = string
  default     = null
}
