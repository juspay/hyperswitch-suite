# Identity / naming
variable "compartment_id" {
  description = "OCID of the compartment that holds the cluster. This is OCI's scoping context and replaces the AWS module's vpc_id-as-scope: on OCI the VCN is implied by subnet_id, while ownership/quota/policy scope is the compartment. Flat-compartment first cut - every resource this module creates lands in this one compartment."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment (or root tenancy) OCID, e.g. ocid1.compartment.oc1..aaaa..."
  }
}

variable "environment" {
  description = "Environment short name (dev, integ, sandbox, prod). Used for naming and freeform tags."
  type        = string
}

variable "project_name" {
  description = "Project name used for naming and freeform tags."
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "Region identifier (e.g. ap-mumbai-1), used for freeform tags only. Actual placement is decided by subnet_id and the provider's own region - this variable does not move the cluster."
  type        = string
  default     = null
}

variable "name_suffix" {
  description = <<-EOT
    Optional suffix appended to the generated display name, e.g. "ratelimiter".

    This module is deliberately NOT a singleton. On AWS the same elasticache
    composition module is instantiated more than once per account - the shared
    payments/session cache via the catalog unit, plus a dedicated instance
    embedded in application-resources/ratelimiter, plus locker's own instance.
    A second OCI catalog unit must be able to instantiate this module again in
    the same compartment without colliding, so nothing here hardcodes a name.
  EOT
  type        = string
  default     = null
}

variable "display_name" {
  description = "Full override of the cluster display name. Leave null to use '<environment>-<project_name>-valkey[-<name_suffix>]'."
  type        = string
  default     = null
}

# Network placement - this module places into pre-existing network objects and
# creates no subnet, VCN, NSG or security list of its own.
variable "subnet_id" {
  description = <<-EOT
    OCID of the PRIVATE subnet the cluster's nodes get their endpoints in.

    Singular, not a list. This replaces three AWS variables at once
    (subnet_ids, create_elasticache_subnet_group, elasticache_subnet_group_name):
    OCI Cache has no subnet-group resource, the subnet is an argument on the
    cluster itself, so there is nothing to create or name. There is also no
    public-endpoint option in the schema at all - every endpoint OCI hands back
    is a private IP / private FQDN.
  EOT
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.subnet\\.", var.subnet_id))
    error_message = "subnet_id must be a subnet OCID, e.g. ocid1.subnet.oc1.ap-mumbai-1.aaaa..."
  }
}

variable "vcn_id" {
  description = <<-EOT
    OCID of the VCN the module-owned NSG is created in.

    Only required when create_nsg is true (the default), bringing this module
    in line with the sibling `database` module, which already creates its own
    NSG.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.vcn_id == null || can(regex("^ocid1\\.vcn\\.", var.vcn_id))
    error_message = "vcn_id must be a VCN OCID, e.g. ocid1.vcn.oc1.ap-mumbai-1.aaaa..."
  }
}

variable "create_nsg" {
  description = <<-EOT
    Create a module-owned, EMPTY network security group and attach the cluster
    to it, exporting its OCID as nsg_id. Mirrors the `database` module's
    create_nsg and AWS's create_security_group.

    NSGs only, never VCN security lists, because only NSGs expose the
    standalone per-rule resource the security-last phase unit needs to attach
    cross-module rules without owning the NSG itself. This module originally
    created no NSG, relying on the shared subnet security list - weaker
    isolation than every sibling data-tier module. Default true fixes that.
  EOT
  type        = bool
  default     = true
}

variable "nsg_ids" {
  description = <<-EOT
    OCIDs of ADDITIONAL, pre-existing Network Security Groups to attach
    alongside the module-owned one (0-5 total including it).

    Replaces the AWS module's create_security_group / security_group_name /
    existing_security_group_ids trio.
  EOT
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.nsg_ids) <= 5
    error_message = "OCI Cache accepts at most 5 NSGs per cluster."
  }
}

# Engine
variable "software_version" {
  description = <<-EOT
    OCI Cache engine version. One combined field where AWS has two
    (engine + engine_version) - there is no separate engine selector, the
    engine is encoded in the version literal.

    Verified available 2026-09-03: VALKEY_8_1 (recommended, GA Apr 2026),
    VALKEY_7_2, REDIS_7_0. Extend this list when Oracle GAs a new version;
    a strict list is intentional so a typo fails at plan rather than 20
    minutes into a create call.

    Note the AWS fleet pins engine_version = "8.2" and OCI's newest Valkey is
    8.1 - close, not identical, and not verdict-changing.
  EOT
  type        = string
  default     = "VALKEY_8_1"

  validation {
    condition     = contains(["VALKEY_8_1", "VALKEY_7_2", "REDIS_7_0"], var.software_version)
    error_message = "software_version must be one of VALKEY_8_1, VALKEY_7_2, REDIS_7_0 (verified against the OCI Cache release notes on 2026-09-03)."
  }
}

# Topology
variable "cluster_mode" {
  description = <<-EOT
    SHARDED or NONSHARDED. Literals confirmed from the oci_redis_redis_cluster
    schema docs (node_count: "...when clusterMode is SHARDED... when clusterMode
    is NONSHARDED").

    SHARDED   - shard_count independent write shards, node_count nodes per shard.
    NONSHARDED - one primary holding all data, node_count total nodes, the
                 non-primary ones read-only replicas.
  EOT
  type        = string
  default     = "NONSHARDED"

  validation {
    condition     = contains(["SHARDED", "NONSHARDED"], var.cluster_mode)
    error_message = "cluster_mode must be exactly \"SHARDED\" or \"NONSHARDED\"."
  }
}

variable "shard_count" {
  description = <<-EOT
    Number of shards. Only meaningful when cluster_mode = "SHARDED"; must be
    null when NONSHARDED.

    OCI requires an ODD shard count between 3 and 99. A 2-shard topology
    CANNOT BE CREATED on OCI, at all, by any module; this module does not invent
    a mechanical translation.

    The operator picks one of two real trade-offs when instantiating the unit,
    as a per-instantiation `values` decision:
      1. shard_count = 3 (OCI's minimum sharded config) - keeps independent
         write sharding, but is 50% more nodes than a 2-shard layout for no
         capacity reason other than satisfying the constraint.
      2. cluster_mode = "NONSHARDED" - fits OCI's limits but is a genuine
         write-throughput regression from 2 write shards, not a rename.
    Both change cost/capacity, so this is a capacity-planning call made with
    real utilization numbers, not a default baked into a module.

    Whether the odd/>=3 rule is a hard product limit or a raisable service
    limit is unconfirmed.
  EOT
  type        = number
  default     = null

  validation {
    # Self-contained (no cross-variable reference, so it holds on Terraform
    # >= 1.5). The "only when SHARDED" half is enforced as a resource
    # precondition in main.tf.
    condition     = var.shard_count == null || (var.shard_count >= 3 && var.shard_count <= 99 && var.shard_count % 2 == 1)
    error_message = "shard_count must be an ODD number between 3 and 99. OCI rejects even shard counts and anything below 3 - a 2-shard AWS topology has no direct OCI equivalent; choose 3 shards or cluster_mode = \"NONSHARDED\"."
  }
}

variable "node_count" {
  description = <<-EOT
    Nodes PER SHARD when cluster_mode = "SHARDED"; TOTAL nodes when NONSHARDED.

    Collapses four AWS variables (num_cache_clusters, replicas_per_node_group,
    and half of cluster_mode/num_node_groups) into one. There is no separate
    replica count: node_count = 1 + replicas.

    High availability is implicit: any cluster
    with node_count > 1 runs 1 primary + replicas with automatic promotion.
    There is no automatic_failover_enabled / multi_az_enabled toggle to port -
    failover is a property of having replicas, not an option. Keep node_count
    >= 2 anywhere HA matters.
  EOT
  type        = number
  default     = 2

  validation {
    condition     = var.node_count >= 1
    error_message = "node_count must be at least 1."
  }
}

variable "node_memory_in_gbs" {
  description = <<-EOT
    Memory per node in GB (2-500).

    Replaces AWS's node_type instance-class strings entirely - OCI has no
    instance classes here, memory is requested directly. The live AWS shared
    cache uses cache.m6g.large (6.38 GiB usable), so ~6 is the like-for-like
    figure when porting prod; dev should be sized down deliberately rather
    than copied, the same call the GCP dev valkey unit already made.
  EOT
  type        = number
  default     = 4

  validation {
    condition     = var.node_memory_in_gbs >= 2 && var.node_memory_in_gbs <= 500
    error_message = "node_memory_in_gbs must be between 2 and 500."
  }
}

# Encryption
# IN TRANSIT: deliberately NO transit_encryption_enabled/transit_encryption_mode
# variable here. OCI Cache is TLS-only with no Terraform-level off switch
# (Oracle: "By default, OCI Cache only supports TLS connections"). This is the
# opposite of the AWS module (transit_encryption_enabled = false in every live
# unit), and exposing a toggle that cannot toggle would be a lie in the module's
# interface. The consequence is real and NOT closed: if the Valkey client cannot
# negotiate TLS, connections fail outright rather than degrading. Confirm the
# client supports TLS, or open an Oracle support request, before pointing a
# workload at a cluster.
# AT REST: no argument exists and whether OCI Cache encrypts at rest by default
# or supports CMEK via Vault is NOT documented anywhere checked - an unverified
# gap, not a confirmed equivalence, so no at_rest_encryption/kms_key variable.

# Engine parameters (the parameter-group analogue)
variable "oci_cache_config_set_id" {
  description = "OCID of a PRE-EXISTING OCI Cache Config Set to attach. Mutually exclusive with create_config_set. The AWS analogue is parameter_group_name."
  type        = string
  default     = null
}

variable "create_config_set" {
  description = <<-EOT
    Create a module-owned config set from config_set_parameters.

    Defaults false, on purpose: every AWS unit reviewed uses the stock
    default.valkey8.cluster.on parameter group, i.e. no customization, so the
    first cut should create zero config sets. The knob is plumbed so prod
    us-east-1's custom group has somewhere to land later.
  EOT
  type        = bool
  default     = false
}

variable "config_set_parameters" {
  description = "Engine parameters as a flat key/value map, e.g. { maxmemory-policy = \"volatile-lru\" }. Values are strings on OCI even when they represent numbers or booleans. Ignored unless create_config_set is true."
  type        = map(string)
  default     = {}
}

variable "config_set_description" {
  description = "Description for the module-created config set."
  type        = string
  default     = null
}

# Backup / restore
variable "create_backup" {
  description = <<-EOT
    Create one oci_redis_oci_cache_backup of this cluster.

    OCI's backup is a DISCRETE, EXPLICITLY-TRIGGERED resource: creating it takes
    exactly one backup. There is no snapshot_window / schedule / backup-policy
    argument anywhere in the redis service's resource surface, so a "nightly
    snapshot, keep N days" behaviour does NOT port. Recurring backups need
    external automation (OCI Resource Scheduler, a cron pipeline) that creates
    a new backup on a schedule and prunes old ones - new operational surface.

    Defaults false so the first apply provisions the cluster only.
  EOT
  type        = bool
  default     = false
}

variable "backup_retention_period_in_days" {
  description = "How long the module-created backup is kept. The nearest thing to AWS's snapshot_retention_limit (7 in every live AWS unit) - but it governs ONE backup, not a rolling window."
  type        = number
  default     = 7
}

variable "backup_source" {
  description = "Whether the backup is taken from a replica or the primary node. Leave null for the service default."
  type        = string
  default     = null
}

variable "backup_export_to_object_storage_trigger" {
  description = <<-EOT
    Increment to trigger an export of the backup into Object Storage.

    Step 2 of the four-step cross-region DR substitute (backup -> export ->
    Object Storage cross-region replication -> re-import). Steps 3 and 4 are
    deliberately OUT OF SCOPE for this module.
  EOT
  type        = number
  default     = null
}

variable "backup_id" {
  description = "Restore the new cluster from an existing OCI Cache Backup OCID, at create time only. AWS analogue: snapshot_name. Mutually exclusive with import_from_object_storage."
  type        = string
  default     = null
}

variable "import_from_object_storage" {
  description = <<-EOT
    Restore the new cluster from raw RDB file(s) in Object Storage, at create
    time only. AWS analogue: snapshot_arns. Mutually exclusive with backup_id.

    OCI has two restore paths where AWS has one, so feature 11 is FULL. This is
    also the re-import end of the DR substitute path.
  EOT
  type = object({
    bucket    = string
    namespace = string
    objects   = list(string)
  })
  default = null
}

# Maintenance
# Deliberately NO maintenance_window variable: routine OS/security patching on
# OCI Cache is Oracle-managed (blue/green node swap) with no customer-configurable
# window - platform behaviour, not a missing argument. Engine version upgrades ARE
# customer-triggered: software_version is (Updatable), so change it to upgrade.
# There is no apply_immediately equivalent; updates apply when applied.

# AUTH / users
variable "cache_users" {
  description = <<-EOT
    OCI Cache users to create and attach, keyed by user name.

    Richer than the AWS surface it replaces: AWS offers one shared auth_token
    string plus a reference to externally-created user_group_ids. OCI has a
    native multi-user ACL model, so this costs two resources (user + a single
    attachment) instead of one variable.

    Defaults to {} - AUTH is unset in every live AWS unit reviewed, so the
    first cut creates no users. Passwords are NOT accepted here; see
    cache_user_hashed_passwords.

    authentication_type: PASSWORD is the only literal confirmed against the
    schema. The OCI Cache overview advertises "IAM authentication" and
    oci_redis_redis_cluster_create_identity_token exists, but the exact IAM
    literal is unconfirmed, so this module does
    not validate the value against a list it cannot vouch for.
  EOT
  type = map(object({
    acl_string          = string
    description         = string
    authentication_type = optional(string, "PASSWORD")
    status              = optional(string, "ON")
  }))
  default = {}
}

variable "cache_user_hashed_passwords" {
  description = <<-EOT
    SHA-256 HASHED passwords per cache_users key. Required by OCI when
    authentication_type = PASSWORD.

    Kept as a separate, sensitive variable rather than a field inside
    cache_users because cache_users drives a for_each, and Terraform refuses to
    iterate a sensitive value. This module never accepts, derives or stores a
    plaintext password - hash upstream (OCI Vault / the secret pipeline) and
    pass the digest.
  EOT
  type        = map(list(string))
  default     = {}
  sensitive   = true
}

# Tagging
variable "freeform_tags" {
  description = "Additional OCI freeform tags, merged over the module's own. The AWS `tags` map and the GCP `labels` map both land here."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "OCI defined tags, e.g. { \"Operations.CostCenter\" = \"42\" }. Namespaces must already exist in the tenancy."
  type        = map(string)
  default     = {}
}

# Timeouts
variable "timeouts" {
  description = "Per-operation timeouts. The provider defaults to 20m for all three; a large sharded cluster create can exceed that, and the DR discussion relies on the create timeout being visible, so it is an input rather than a hidden default."
  type = object({
    create = optional(string, "60m")
    update = optional(string, "60m")
    delete = optional(string, "60m")
  })
  default = {}
}
