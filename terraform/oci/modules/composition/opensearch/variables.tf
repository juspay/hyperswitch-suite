# =============================================================================
# Identity and naming
# =============================================================================

variable "environment" {
  description = "Environment short name (dev, sandbox, prod)."
  type        = string
}

variable "project_name" {
  description = "Project name. Part of the cluster's display name."
  type        = string
}

variable "region" {
  description = "OCI region identifier. Carried for naming parity with the AWS module; no resource here takes a region argument."
  type        = string
  default     = null
}

variable "compartment_id" {
  description = "OCID of the compartment the cluster is created in."
  type        = string
}

variable "tenancy_ocid" {
  description = "Tenancy OCID. Only used when create_service_policy = true and the policy is scoped at the tenancy rather than the compartment."
  type        = string
  default     = null
}

variable "display_name" {
  description = "Cluster display name. Replaces domain_name; null derives <env>-<project>-opensearch."
  type        = string
  default     = null
}

# =============================================================================
# Network
# =============================================================================
# OCI's cluster resource takes compartment context for the VCN and the subnet
# INDEPENDENTLY of the cluster's own compartment - three compartment arguments
# where AWS had none, because AWS scoped everything by account plus VPC.

variable "vcn_id" {
  description = "OCID of the VCN the cluster attaches to."
  type        = string
}

variable "vcn_compartment_id" {
  description = "Compartment OCID that owns the VCN. Defaults to compartment_id. No AWS analogue."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = <<-EOT
    OCID of the subnet the cluster's endpoints land in. SINGULAR, replacing AWS's
    subnet_ids list - verified against the resource schema, oci_opensearch_opensearch_cluster
    takes exactly one subnet_id (required). This resolves check sheet open
    question 9.6's first half.

    Normally vpc-network's subnets_by_tier["data-stack"].
  EOT
  type        = string
}

variable "subnet_compartment_id" {
  description = "Compartment OCID that owns the subnet. Defaults to compartment_id. No AWS analogue."
  type        = string
  default     = null
}

variable "create_nsg" {
  description = <<-EOT
    Create the module-owned, deliberately empty NSG and hand it to the cluster.

    Collapses four AWS variables (create_security_group, security_group_name,
    security_group_description, existing_security_group_ids) into one boolean plus
    var.nsg_id, because the cluster resource accepts exactly ONE nsg_id, not a
    list - so "several existing security groups" has no expressible counterpart.
  EOT
  type        = bool
  default     = true
}

variable "nsg_id" {
  description = "Pre-existing NSG OCID to use instead of a module-owned one. Ignored when create_nsg = true."
  type        = string
  default     = null
}

# =============================================================================
# Engine
# =============================================================================

variable "software_version" {
  description = <<-EOT
    OpenSearch engine version, e.g. "2.11.0". Replaces engine_version
    ("OpenSearch_2.13" on AWS).

    DO NOT ASSUME THE AWS VALUE PORTS. AWS and OCI each control their own
    supported-version list and upgrade cadence independently; "OpenSearch_2.13"
    is an AWS-shaped string and is not a valid OCI software_version. Check sheet
    open question 9.5, UNRESOLVED - confirm against `oci opensearch` before the
    first apply. This variable has no default deliberately, so nobody inherits a
    guess.
  EOT
  type        = string
}

# =============================================================================
# Data node tier (check sheet feature 1, FULL)
# =============================================================================

variable "data_node_count" {
  description = "Number of data nodes. Replaces cluster_config.instance_count."
  type        = number
  default     = 1
}

variable "data_node_host_type" {
  description = "Host type for data nodes: FLEX (VM) or BM (bare metal)."
  type        = string
  default     = "FLEX"
}

variable "data_node_host_ocpu_count" {
  description = <<-EOT
    OCPUs per data node. Together with data_node_host_memory_gb this replaces
    AWS's single instance_type string.

    OCI's model is MORE granular, not less: OCPU and memory are set independently
    per node tier rather than picked from a fixed instance-type menu.
  EOT
  type        = number
  default     = 2
}

variable "data_node_host_memory_gb" {
  description = "Memory per data node, GB."
  type        = number
  default     = 32
}

variable "data_node_storage_gb" {
  description = <<-EOT
    Storage per data node, GB. Replaces ebs_options.volume_size.

    WHAT DOES NOT PORT: AWS's ebs_options.iops and ebs_options.throughput. There
    is NO IOPS or throughput argument on this resource - confirmed by reading the
    full schema, not inferred. Storage performance is derived from the node's
    shape/OCPU allocation. If this workload turns out to be storage-IOPS-bound
    rather than compute-bound, the only lever is a bigger node. Check sheet
    feature 4, verdict PARTIAL (section 4.2); the open question is now CLOSED as
    a confirmed gap rather than an unverified one.
  EOT
  type        = number
  default     = 50
}

variable "data_node_host_shape" {
  description = "Optional explicit shape for data nodes. Normally left null and derived from host type + OCPU/memory."
  type        = string
  default     = null
}

# =============================================================================
# Master (leader) node tier (check sheet feature 2, FULL)
# =============================================================================

variable "master_node_count" {
  description = <<-EOT
    Number of dedicated master (leader) nodes.

    DIVERGENCE WORTH KNOWING: AWS makes this tier OPTIONAL -
    dedicated_master_enabled defaults to false and this module's AWS counterpart
    leaves it off. On OCI master_node_count / _host_ocpu_count / _host_memory_gb /
    _host_type are ALL REQUIRED arguments on the cluster resource. There is no
    "no dedicated master" configuration to port to; the tier is mandatory and
    costs money in every environment, including dev.
  EOT
  type        = number
  default     = 3
}

variable "master_node_host_type" {
  description = "Host type for master nodes: FLEX or BM."
  type        = string
  default     = "FLEX"
}

variable "master_node_host_ocpu_count" {
  description = "OCPUs per master node. Replaces the OCPU half of dedicated_master_type."
  type        = number
  default     = 2
}

variable "master_node_host_memory_gb" {
  description = "Memory per master node, GB. Replaces the memory half of dedicated_master_type."
  type        = number
  default     = 16
}

variable "master_node_host_shape" {
  description = "Optional explicit shape for master nodes."
  type        = string
  default     = null
}

# =============================================================================
# OpenSearch Dashboards tier (check sheet feature 11, FULL)
# =============================================================================

variable "opendashboard_node_count" {
  description = <<-EOT
    Number of OpenSearch Dashboards nodes.

    AWS has no counterpart argument at all - Dashboards is part of the managed
    domain and is not separately sized. On OCI it is a REQUIRED, independently
    sized node tier. Another place OCI's model is more granular and, here, more
    expensive by default.
  EOT
  type        = number
  default     = 1
}

variable "opendashboard_node_host_ocpu_count" {
  description = "OCPUs per Dashboards node."
  type        = number
  default     = 1
}

variable "opendashboard_node_host_memory_gb" {
  description = "Memory per Dashboards node, GB."
  type        = number
  default     = 8
}

variable "opendashboard_node_host_shape" {
  description = "Optional explicit shape for Dashboards nodes."
  type        = string
  default     = null
}

# =============================================================================
# Optional node tiers - no AWS counterpart at all
# =============================================================================
# AWS's aws_opensearch_domain has one data tier plus an optional master tier and
# an optional UltraWarm tier. OCI exposes six independently sized tiers. The
# three below have no AWS analogue and are all opt-in; the AWS module's
# warm_enabled / warm_type / warm_count have no direct mapping and are dropped
# rather than approximated onto search or ml nodes, which are different things.

variable "search_node_count" {
  description = "Number of dedicated search nodes. No AWS counterpart. 0 disables the tier."
  type        = number
  default     = 0
}

variable "search_node_host_ocpu_count" {
  description = "OCPUs per search node. Only read when search_node_count > 0."
  type        = number
  default     = null
}

variable "search_node_host_memory_gb" {
  description = "Memory per search node, GB. Only read when search_node_count > 0."
  type        = number
  default     = null
}

variable "search_node_storage_gb" {
  description = "Storage per search node, GB. Only read when search_node_count > 0."
  type        = number
  default     = null
}

variable "coordinator_node_count" {
  description = "Number of coordinator nodes. No AWS counterpart. 0 disables the tier."
  type        = number
  default     = 0
}

variable "coordinator_node_host_ocpu_count" {
  description = "OCPUs per coordinator node. Only read when coordinator_node_count > 0."
  type        = number
  default     = null
}

variable "coordinator_node_host_memory_gb" {
  description = "Memory per coordinator node, GB. Only read when coordinator_node_count > 0."
  type        = number
  default     = null
}

variable "ml_node_count" {
  description = "Number of ML nodes. No AWS counterpart. 0 disables the tier."
  type        = number
  default     = 0
}

variable "ml_node_host_ocpu_count" {
  description = "OCPUs per ML node. Only read when ml_node_count > 0."
  type        = number
  default     = null
}

variable "ml_node_host_memory_gb" {
  description = "Memory per ML node, GB. Only read when ml_node_count > 0."
  type        = number
  default     = null
}

variable "ml_node_storage_gb" {
  description = "Storage per ML node, GB. Only read when ml_node_count > 0."
  type        = number
  default     = null
}

# =============================================================================
# Security (check sheet feature 6, FULL)
# =============================================================================

variable "security_mode" {
  description = <<-EOT
    DISABLED, PERMISSIVE or ENFORCING. The equivalent of AWS's
    advanced_security_options.enabled plus its enforcement posture in one
    argument.
  EOT
  type        = string
  default     = null
}

variable "security_master_user_name" {
  description = "Fine-grained-access-control master user name. Replaces master_user_name."
  type        = string
  default     = null
}

variable "security_master_user_password_hash" {
  description = <<-EOT
    Master user password HASH, not a plaintext password.

    A REAL INPUT-SHAPE DIFFERENCE, not a rename: AWS takes master_user_password
    (plaintext, or an IAM ARN via master_user_arn). OCI takes a pre-computed hash,
    so the hashing happens outside Terraform and no plaintext ever enters this
    module. AWS's master_user_arn - identity-based master access - has no OCI
    counterpart and is dropped.

    This module never generates or logs a credential. Supply the hash from the
    caller's own secret store.
  EOT
  type        = string
  default     = null
  sensitive   = true
}

# =============================================================================
# Certificates (check sheet feature 7, FULL)
# =============================================================================

variable "certificate_config" {
  description = <<-EOT
    Custom endpoint certificates. Replaces AWS's domain_endpoint_options
    (custom_endpoint_enabled / custom_endpoint / custom_endpoint_certificate_arn),
    with OCI Certificates OCIDs instead of ACM ARNs.

    AWS's enforce_https and tls_security_policy have no separate arguments here -
    TLS posture is folded into this block and the service's own defaults.
  EOT
  type = object({
    cluster_certificate_mode             = optional(string)
    dashboard_certificate_mode           = optional(string)
    open_search_api_certificate_id       = optional(string)
    open_search_dashboard_certificate_id = optional(string)
  })
  default = null
}

# =============================================================================
# Maintenance (SUBSTITUTE - check sheet feature 8, section 4.4)
# =============================================================================

variable "maintenance_notification_email_ids" {
  description = <<-EOT
    Email addresses notified about maintenance events.

    THIS IS THE WHOLE MAINTENANCE SURFACE, and it is a notification channel, not
    a scheduling control. AWS exposes auto_tune_enabled,
    auto_tune_rollback_on_disable, auto_software_update_enabled and a customer-set
    off_peak_window_start_hour. None of them have counterparts: Oracle's control
    plane decides when, and claims patching/upgrading/backups happen "without
    downtime". All five AWS variables are DROPPED rather than approximated.

    Different guarantee (always-safe) rather than a missing capability
    (customer-scheduled). Check sheet section 8 item 1: ORACLE GATE ITEM,
    NOT YET CONSULTED - and the "without downtime" claim is worth verifying in
    dev rather than accepting from marketing copy.
  EOT
  type        = list(string)
  default     = []
}

# =============================================================================
# Service control-plane authorization (SUBSTITUTE - feature 12, section 4.6)
# =============================================================================

variable "create_service_policy" {
  description = <<-EOT
    Create the IAM policy letting the OpenSearch control plane attach to this
    compartment's VCN. Replaces aws_iam_service_linked_role (var.create_service_linked_role).

    OCI has no service-linked-role object. The equivalent is a service POLICY,
    granted once per compartment before the first cluster can attach to a
    customer VCN. Defaults to false because the policy usually belongs to a
    shared identity/compartment module rather than to each consumer - and because
    creating it needs IAM write permission this module's caller may not have.
  EOT
  type        = bool
  default     = false
}

variable "service_policy_statements" {
  description = <<-EOT
    Override the service policy statements.

    When empty the module emits the standard OCI managed-service network grant for
    the `opensearch` service principal. THE EXACT PRINCIPAL NAME IS INFERRED BY
    ANALOGY to other network-attached OCI managed services and was NOT
    independently confirmed - check sheet open question 9.4, UNRESOLVED. If it is
    wrong, the apply fails cleanly and visibly rather than silently, which is why
    shipping the inference is acceptable.
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

# =============================================================================
# Timeouts
# =============================================================================

variable "create_timeout" {
  description = "Cluster create timeout. AWS carried the same variable because managed-search provisioning is slow on both clouds."
  type        = string
  default     = "60m"
}

variable "update_timeout" {
  description = "Cluster update timeout."
  type        = string
  default     = "60m"
}

variable "delete_timeout" {
  description = "Cluster delete timeout."
  type        = string
  default     = "60m"
}
