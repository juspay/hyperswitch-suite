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

variable "region" {
  description = "OCI region identifier, e.g. ap-mumbai-1. Carried for naming/labelling parity with the AWS module; no resource here takes a region argument."
  type        = string
  default     = null
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
    data.oci_identity_availability_domains.

    ap-mumbai-1 has exactly ONE availability domain, so a 3-node Cassandra ring
    has no AZ-equivalent spread available. Fault domains are the only in-region
    isolation - see var.fault_domains.
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
  description = "OCID of the VCN. Needed only to create the module-owned NSG."
  type        = string
}

variable "subnet_id" {
  description = <<-EOT
    OCID of the subnet the node VNICs land in. Normally vpc-network's
    subnets_by_tier["data-stack"].

    The AWS module also took additional_subnet_ids, for spreading nodes across
    AZs. That variable is DROPPED, not renamed: OCI subnets are regional, so
    there is no per-AZ subnet to add, and ap-mumbai-1 has one AD regardless.
  EOT
  type        = string
}

variable "create_nsg" {
  description = "Create the module-owned, deliberately empty NSG. Rules are written by composition/security-rules, the security-last phase."
  type        = bool
  default     = true
}

variable "additional_nsg_ids" {
  description = "Pre-existing NSG OCIDs to attach to node VNICs in addition to the module-owned one."
  type        = list(string)
  default     = []
}

variable "assign_private_dns_record" {
  description = "Register an internal DNS A record for each node VNIC."
  type        = bool
  default     = true
}

variable "reserved_ip_addresses" {
  description = <<-EOT
    Optional explicit IPv4 addresses for the nodes' reserved private IPs, one per
    node, inside subnet_id's CIDR. Null lets OCI allocate.

    These addresses are the gossip seed list. Pinning them makes the ring's
    addressing reproducible from configuration rather than from allocation order.
  EOT
  type        = list(string)
  default     = null
}

# =============================================================================
# Cluster
# =============================================================================

variable "cluster_name" {
  description = "Cassandra cluster name, passed through to the node bootstrap config unchanged."
  type        = string
  default     = "cassandra-cluster"
}

variable "node_count" {
  description = "Number of Cassandra nodes. AWS default is 3."
  type        = number
  default     = 3
}

variable "replication_factor" {
  description = "Keyspace replication factor, passed through to the node bootstrap config unchanged."
  type        = number
  default     = 3
}

variable "idle_timeout" {
  description = "Client idle timeout, passed through to the node bootstrap config unchanged."
  type        = number
  default     = 60000
}

variable "default_config_path" {
  description = "Path inside the image where the node bootstrap script writes the rendered Cassandra config."
  type        = string
  default     = "/etc/cassandra/cassandra.yaml"
}

variable "config_profile" {
  description = "Tuning profile name handed to the node bootstrap script. AWS uses \"ReadWriteHeavy\"."
  type        = string
  default     = "ReadWriteHeavy"
}

variable "cassandra_ports" {
  description = <<-EOT
    Named Cassandra ports. Carried unchanged from AWS, but note that on AWS this
    variable also fed the inline security-group rules. Here it feeds nothing but
    the bootstrap config and the outputs: the rules live in
    composition/security-rules, which reads these values from its own inputs.
  EOT
  type = object({
    native    = optional(number, 9042)
    storage   = optional(number, 7000)
    ssl       = optional(number, 7001)
    jmx       = optional(number, 7199)
    thrift    = optional(number, 9160)
    inspectIT = optional(number, 8778)
  })
  default = {}
}

variable "user_data_override" {
  description = "Raw node user_data. When null the module builds the same JSON blob the AWS module does."
  type        = string
  default     = null
}

# =============================================================================
# Compute
# =============================================================================

variable "image_id" {
  description = <<-EOT
    OCID of the custom image the nodes boot from. Replaces ami_id.

    NO IMAGE BUILD PIPELINE EXISTS FOR OCI YET (vm-tier-and-images.md section 4).
    Do not apply a consuming unit against a placeholder - that is the state the
    GCP port is still stuck in.
  EOT
  type        = string
}

variable "shape" {
  description = <<-EOT
    Compute shape. Flexible shapes decouple OCPU/memory from the shape name, so
    AWS's single instance_type becomes shape + ocpus + memory_in_gbs. m7g.large
    (2 vCPU / 8 GB non-SMT Graviton3) maps to 2 OCPU / 8 GB. Shape family is a
    vm-tier-and-images.md decision.
  EOT
  type        = string
  default     = "VM.Standard.E5.Flex"
}

variable "ocpus" {
  description = "OCPUs per node. One OCPU is one physical core (two vCPUs on x86 SMT shapes)."
  type        = number
  default     = 2
}

variable "memory_in_gbs" {
  description = "Memory per node, GB."
  type        = number
  default     = 16
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size per node, GB. Minimum 50."
  type        = number
  default     = 50
}

variable "boot_volume_vpus_per_gb" {
  description = "Boot volume VPUs per GB. 0 = Lower Cost, 10 = Balanced, 20 = Higher Performance, 30-120 = Ultra High Performance."
  type        = number
  default     = 10
}

# =============================================================================
# Storage
# =============================================================================

variable "data_volume_size_in_gbs" {
  description = "Dedicated data volume size per node, GB. Replaces ebs_volume_size."
  type        = number
  default     = 200
}

variable "data_volume_vpus_per_gb" {
  description = <<-EOT
    Data volume VPUs per GB. Replaces ebs_volume_type ('gp3').

    10 (Balanced) = 60 IOPS/GB up to 25,000/volume; 20 (Higher Performance) =
    75 IOPS/GB up to 35,000; 30+ (Ultra High Performance) = 90-225 IOPS/GB up to
    300,000. A 200 GB Balanced volume already delivers 12,000 IOPS against gp3's
    3,000 baseline, so capacity is not the constraint here - see
    var.data_volume_attachment_type for the one that is.
  EOT
  type        = number
  default     = 10
}

variable "data_volume_attachment_type" {
  description = <<-EOT
    "iscsi" (default) or "paravirtualized". See storage.tf - this default is a
    deliberate choice with a new failure mode behind it, and it is an oracle gate
    item (clickhouse check sheet section 8 item 4, shared with this module).
  EOT
  type        = string
  default     = "iscsi"

  validation {
    condition     = contains(["paravirtualized", "iscsi"], var.data_volume_attachment_type)
    error_message = "data_volume_attachment_type must be \"paravirtualized\" or \"iscsi\"."
  }
}

variable "volume_kms_key_id" {
  description = "Optional Vault key OCID for boot and block volume encryption. Encryption is always on with an Oracle-managed key and cannot be disabled; this only swaps the key. Replaces kms_key_id."
  type        = string
  default     = null
}

# =============================================================================
# Hardening and agents
# =============================================================================

variable "are_legacy_imds_endpoints_disabled" {
  description = <<-EOT
    Disable the legacy /v1 metadata endpoints - the equivalent of
    metadata_options.http_tokens = "required".

    The AWS module also set metadata_options.instance_metadata_tags = "enabled".
    That has NO counterpart here, and not because it is missing: OCI's metadata
    service exposes instance tags to the guest with no opt-in flag. That is a
    strictly WIDER default than AWS's, so nothing sensitive may be placed in a
    tag on these instances. Check sheet open question 9.2, UNRESOLVED.
  EOT
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
# Logging
# =============================================================================

variable "enable_logging" {
  description = "Create the OCI Logging log group + custom log. Replaces aws_cloudwatch_log_group."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = <<-EOT
    Retention in days for the custom log. Note the shape difference: on AWS
    retention is a log-GROUP property; on OCI it is per-log
    (oci_logging_log.retention_duration). Valid OCI values are 30-180 days, so
    AWS retentions outside that range cannot be ported literally. Check sheet
    open question 9.4.
  EOT
  type        = number
  default     = 30
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
  description = "Override the dynamic group matching rule. Null emits a compartment-scoped rule - see identity.tf for why a tag-scoped one is not available."
  type        = string
  default     = null
}

variable "policy_statements" {
  description = "Policy statements for the dynamic group. Empty emits a narrow default rather than a port of the AWS role's broad EC2 grants."
  type        = list(string)
  default     = []
}

variable "cluster_tag_name" {
  description = "Freeform tag key marking cluster membership. Carried from AWS, where seed discovery filtered instances on it."
  type        = string
  default     = "cluster"
}

variable "cluster_tag_value" {
  description = "Freeform tag value marking cluster membership."
  type        = string
  default     = "cassandra-cluster"
}

# =============================================================================
# Seed discovery (SUBSTITUTE - check sheet feature 11, section 4.4)
# =============================================================================

variable "enable_seed_discovery" {
  description = <<-EOT
    Build the runtime seed-discovery service (OCI Functions behind API Gateway).

    DEFAULT FLIPPED TO FALSE, where the AWS module's create_seed_discovery
    defaults ON. This is a deliberate behaviour change, not a mechanical port -
    read seed-discovery.tf before turning it on or leaving it off.
    Check sheet section 8 item 4: ORACLE GATE ITEM, NOT YET CONSULTED.
  EOT
  type        = bool
  default     = false
}

variable "seeds_url" {
  description = "Externally-supplied seed endpoint. When set, no discovery service is built and this value is passed through to the nodes and to the seeds_url output."
  type        = string
  default     = null
}

variable "seed_discovery_image" {
  description = <<-EOT
    Fully-qualified OCIR image for the seed-discovery Function, e.g.
    bom.ocir.io/<namespace>/<repo>:<tag>.

    OCI Functions deploy from a CONTAINER IMAGE, not a zip upload. That is a
    different artifact pipeline from the AWS Lambda zip this replaces and from
    GCP's Cloud Run source bucket, and it does not exist yet. Required when
    enable_seed_discovery = true. Check sheet open question 9.3.
  EOT
  type        = string
  default     = null
}

variable "seed_discovery_memory_in_mbs" {
  description = "Memory for the seed-discovery Function, MB."
  type        = string
  default     = "256"
}

variable "seed_discovery_path" {
  description = "API Gateway route path for seed discovery. AWS used /CassandraSeedNode."
  type        = string
  default     = "/CassandraSeedNode"
}

variable "seed_discovery_gateway_endpoint_type" {
  description = <<-EOT
    PRIVATE or PUBLIC. AWS used a PRIVATE API Gateway fronted by a VPC endpoint
    (api_gateway_vpce_id). OCI's PRIVATE gateway needs no endpoint object at all -
    it is simply attached to a subnet - so api_gateway_vpce_id is dropped rather
    than renamed.
  EOT
  type        = string
  default     = "PRIVATE"
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
