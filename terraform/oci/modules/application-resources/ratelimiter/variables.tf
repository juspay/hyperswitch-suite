# ratelimiter - a statement factory plus a pass-through for the dedicated
# cache's connection details.
#   1. The dedicated cache is a SECOND `oci-cache-valkey` catalog unit
#      (name_suffix "ratelimiter"), NOT a nested module - so the security-last
#      rules unit can reach its nsg_id and cache sizing is a per-env stack value.
#   2. The identity grants NOTHING ("1 SA x 0 grants"); on OCI an identity IS its
#      statements, so there is no policy object and `policy_statements` is empty.
#   3. The load-balancer security group is NOT ported - it enforced zero rules
#      in every live root.

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

# -----------------------------------------------------------------------------
# Dedicated cache - PASS-THROUGH ONLY. Wired from the second oci-cache-valkey
# unit's outputs by the catalog unit; this module creates no cache.
# -----------------------------------------------------------------------------

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
  description = "Engine version the dedicated cache runs. Should match the shared cache's - the stated convention is 'same version, fleet-wide'."
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
