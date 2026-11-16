# -----------------------------------------------------------------------------
# ratelimiter - the OCI port of the AWS module of the same name.
#
# The AWS module is 593 lines and does three things: an IRSA role, a DEDICATED
# ElastiCache replication group entirely separate from the platform's shared
# cache, and a load-balancer security group. Each ports differently, and two of
# the three port to somewhere other than this module.
#
# 1. THE DEDICATED CACHE IS REAL AND IS KEPT - BUT AS A SECOND CATALOG UNIT,
#    NOT AS A NESTED MODULE.
#
#    Confirmed: all six AWS live roots that instantiate this module set
#    `elasticache_config.enabled = true` with their own
#    `<env>-<project>-ratelimiter` replication group, distinct from the shared
#    `<env>-<project>-valkey`. Non-sharded, 2 nodes, cache.t3.small - a
#    deliberately smaller, isolated footprint. The reasoning transfers intact:
#    rate limiting is availability-sensitive in a different way than the
#    payments session cache, and isolating it means a maintenance event, a
#    noisy neighbour or a failover on one cannot take down the other.
#
#    ON OCI IT IS A SECOND `oci-cache-valkey` UNIT (`name_suffix =
#    "ratelimiter"`), NOT a nested `module` block inside this one. Three
#    reasons, none cosmetic:
#      (a) The settled network security model puts cross-module NSG rules in a
#          security-last unit that reads each data-tier module's `nsg_id`
#          output. A nested module's outputs are not addressable from another
#          Terragrunt unit; a sibling unit's are.
#      (b) Cache sizing becomes a stack `value` per environment, which is
#          exactly where "dev is smaller than prod" belongs. Nested, it would
#          be a 20-field object threaded through this module's variable surface
#          for no gain.
#      (c) A cache create can run to tens of minutes. Nesting it makes every
#          plan of the rate limiter's identity wait behind it.
#    This is a divergence from the check sheet's section 5, which proposed a
#    nested `module "oci-cache-valkey"`. Recorded here because this file is
#    where a reader would look for the missing module block.
#
#    The GCP-side inconsistency the check sheet flags is NOT copied: GCP puts
#    the shared cache on Valkey-cluster and ratelimiter's dedicated instance on
#    the older classic Memorystore-for-Redis product. AWS uses the identical
#    composition module for both, and so does this port - one module,
#    `oci-cache-valkey`, instantiated twice. Check sheet section 8 item 3 makes
#    that an oracle gate item; it is NOT CONSULTED, and the default taken here
#    is the AWS precedent rather than the GCP one.
#
# 2. THE IDENTITY GRANTS NOTHING, AND ON OCI THAT MEANS THERE IS NOTHING.
#    identity-model.md section 1.2 records this module as "1 SA x 0 grants" -
#    STS only, "the role exists for future use". All three AWS policy inputs
#    (aws_managed, customer_managed, inline) are empty in every one of the six
#    live roots. On AWS an empty role is still an object with an ARN. On OCI an
#    identity IS a set of statements, so zero grants is zero statements is
#    nothing at all: `policy_statements` is EMPTY by default and that is the
#    correct, honest output. The pod authenticates to Kubernetes with its
#    service-account token exactly as before; it simply has no OCI grants,
#    which is what it has on AWS too.
#
# 3. THE LOAD-BALANCER SECURITY GROUP IS NOT PORTED. `create_lb_security_group
#    = true` in every live root, with `lb_ingress_rules = {}` and
#    `lb_egress_rules = {}` - a security group enforcing ZERO rules, everywhere.
#    Reproducing an empty NSG here would port vestigial configuration and would
#    also put NSG ownership in an app module, which the network security model
#    puts in vpc-network and the security-last rules unit. Check sheet open
#    question 3 asks the platform team what that group is actually for; until
#    it is answered there is nothing functional to replicate.
#
# Check sheet: docs/multi-cloud-parity/oci/modules/ratelimiter.md
# -----------------------------------------------------------------------------

variable "compartment_id" {
  description = "OCID of the environment compartment. Default location term for any statement this module renders and the attachment point of the consuming shared policy object."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID."
  }
}

variable "cluster_ids" {
  description = "OCIDs of every OKE cluster running the rate limiter. A list from day one, consistent with every other module in this family. Note it is still required even though the default grant set is empty: it bounds the blast radius of any grant a caller later adds via additional_grants."
  type        = list(string)

  validation {
    condition     = length(var.cluster_ids) > 0
    error_message = "cluster_ids must contain at least one OKE cluster OCID."
  }

  validation {
    condition     = alltrue([for c in var.cluster_ids : can(regex("^ocid1\\.cluster\\.", c))])
    error_message = "every entry in cluster_ids must be an OKE cluster OCID (ocid1.cluster.*)."
  }
}

variable "k8s_namespace" {
  description = "Namespace the rate limiter runs in."
  type        = string
  default     = "ratelimiter"
}

variable "k8s_service_account_name" {
  description = "Service account the rate limiter pod runs as. Nothing annotates it on OCI - there is no eks.amazonaws.com/role-arn equivalent."
  type        = string
  default     = "ratelimiter-sa"
}

variable "additional_grants" {
  description = <<-EOT
    Grants for the rate limiter, in `oke-workload-identity`'s grant shape.

    EMPTY BY DEFAULT, AND THAT IS THE PORT, NOT AN OMISSION. The AWS module
    attaches no managed, customer-managed or inline policy in any of the six
    live roots - the identity carries `sts:AssumeRole` and nothing else. The
    honest OCI translation of "an identity with no cloud grants" is no
    statements.

    Note also that the cache needs NO grant here: OCI Cache is reached over the
    network on 6379 with TLS, authorised by NSG rules and optionally by a cache
    user ACL, not by an IAM statement. Adding a `use redis-*` grant would not
    make a connection work and would widen the identity for nothing.
  EOT
  type = list(object({
    verb           = string
    resource_type  = string
    compartment_id = optional(string)
    condition      = optional(string)
  }))
  default = []

  validation {
    condition     = alltrue([for g in var.additional_grants : contains(["inspect", "read", "use", "manage"], lower(trimspace(g.verb)))])
    error_message = "additional_grants[*].verb must be one of inspect, read, use, manage."
  }
}

variable "shared_statements" {
  description = "Statements from the `shared-policy` module. Replaces `customer_managed_policy_arns` (unset in every live root)."
  type        = list(string)
  default     = []
}

variable "extra_statements" {
  description = "Raw statement strings appended verbatim. Replaces `additional_assume_role_statements` (empty in every live root)."
  type        = list(string)
  default     = []
}

# =============================================================================
# Dedicated cache - PASS-THROUGH ONLY.
#
# These are wired from the second `oci-cache-valkey` unit's outputs by the
# catalog unit. This module creates no cache; see header point 1. All default to
# null so the module stays plannable while that unit is unapplied, and so a
# caller who has not wired it gets nulls rather than a false endpoint.
# =============================================================================

variable "cache_cluster_id" {
  description = "OCID of the dedicated OCI Cache cluster. Answers for AWS `elasticache_replication_group_id` and `elasticache_replication_group_arn` at once - OCI has no ARN concept, the OCID is the globally unique identifier."
  type        = string
  default     = null
}

variable "cache_display_name" {
  description = "Display name of the dedicated cache. Expected to end in `-ratelimiter` (the `name_suffix` that keeps it from colliding with the shared cache in the same compartment). The check at plan time is in outputs.tf."
  type        = string
  default     = null
}

variable "cache_primary_fqdn" {
  description = "Private FQDN of the dedicated cache's primary endpoint. PREFER THIS over the IP: TLS is mandatory on OCI Cache and certificate validation needs the hostname."
  type        = string
  default     = null
}

variable "cache_primary_endpoint_ip_address" {
  description = "Private IP of the primary endpoint. AWS: elasticache_primary_endpoint_address."
  type        = string
  default     = null
}

variable "cache_reader_fqdn" {
  description = "Private FQDN of the replica (read) endpoint."
  type        = string
  default     = null
}

variable "cache_replicas_endpoint_ip_address" {
  description = "Private IP of the replica (read) endpoint. AWS: elasticache_reader_endpoint_address."
  type        = string
  default     = null
}

variable "cache_port" {
  description = "Port the cache serves on. Constant 6379 - OCI Cache neither accepts nor exports a port argument, unlike AWS where it is both settable and exported."
  type        = number
  default     = 6379
}

variable "cache_nsg_id" {
  description = "OCID of the dedicated cache's module-owned NSG. THE consumed output: the security-last rules unit writes the rate limiter's ingress rule into this NSG. Pass-through so a reviewer can see, from this module, which NSG governs reachability."
  type        = string
  default     = null
}

variable "cache_software_version" {
  description = "Engine version the dedicated cache runs. Should match the shared cache's - check sheet open question 5 asks for a stated convention rather than an implicit one; this port's convention is 'same version, fleet-wide'."
  type        = string
  default     = null
}

variable "project_name" {
  description = "Project name for naming and tags."
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment short name (dev, integ, sandbox, prod)."
  type        = string
}

variable "region" {
  description = "Region identifier. Not part of any IAM grant; informational and tagging only."
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Freeform tags, merged over the module's own."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "OCI defined tags, keyed \"namespace.key\"."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# DELETED rather than accepted as no-ops:
#   role_path, max_session_duration      - no role.
#   aws_managed_policy_names             - no managed-policy objects on OCI.
#   assume_role_principals               - no assume step; cross-tenancy is a
#                                          tenancy-root Endorse, not an input
#                                          here, and this module has no
#                                          cross-boundary requirement.
#   create_lb_security_group,
#   lb_ingress_rules, lb_egress_rules    - header point 3.
#   elasticache_config (24 fields)       - header point 1; the cache is a
#                                          sibling unit, so its configuration is
#                                          that unit's `values`, not a nested
#                                          object threaded through here.
# -----------------------------------------------------------------------------
