# -----------------------------------------------------------------------------
# Output contract. 23 AWS outputs collapse to 11.
#
#   role_arn / role_name / role_id / role_unique_id -> NONE / owned by the
#                                shared policy object. No annotation consumes a
#                                role identifier on OCI.
#   *_enabled feature flags   -> only the ones that still describe something
#                                real survive; `oidc_enabled` has no meaning
#                                without an OIDC provider.
#   elasticache_*  (8)        -> cache_* below, pass-through from the sibling
#                                oci-cache-valkey unit.
#   elasticache_security_group_id / _subnet_group_name -> NONE. There is no
#                                subnet-group resource on OCI, and the NSG is
#                                the cache module's own (`cache_nsg_id`).
#   lb_security_group_*       -> NONE. See variables.tf header point 3.
#   region / account_id       -> region only. A compartment OCID is not an
#                                account ID.
# -----------------------------------------------------------------------------

output "policy_statements" {
  description = <<-EOT
    Statements for the environment's shared `oke-workload-identity` object.

    EMPTY BY DEFAULT, AND THAT IS CORRECT. identity-model.md section 1.2 records
    this workload as "1 SA x 0 grants - STS only (identity with no cloud grants;
    the role exists for future use)". On AWS an empty role is still an object
    with an ARN; on OCI an identity is its statements, so there is no object and
    nothing to emit. The pod still runs under `ratelimiter-sa` with
    `automountServiceAccountToken: true`; it simply holds no OCI grants, exactly
    as on AWS.

    In particular the cache needs nothing here: OCI Cache is reached over the
    network on 6379 with mandatory TLS, authorised by NSG rules and optionally a
    cache-user ACL, never by an IAM statement.
  EOT
  value       = local.policy_statements

  precondition {
    condition = alltrue([
      for s in local.rendered_statements :
      can(regex("request\\.principal\\.type='workload'", s))
      && can(regex("request\\.principal\\.namespace='[^']+'", s))
      && can(regex("request\\.principal\\.service_account='[^']+'", s))
      && can(regex("request\\.principal\\.cluster_id='[^']+'", s))
    ])
    error_message = "A rendered statement is missing one of the four request.principal.* conditions. On OCI that fails open, silently."
  }
}

output "workload_grants" {
  description = "The same grants in `oke-workload-identity`'s structured shape. Empty by default. Preferred over policy_statements when wiring the shared policy."
  value       = local.workload_grants
}

output "authorized_workloads" {
  description = "The (cluster_id, namespace, service_account) tuple this module speaks for. Emitted even with no grants, because it is what a future grant would be written against."
  value       = local.authorized_workloads
}

output "statement_count" {
  description = "Statements contributed to the shared policy object. Zero in the ported configuration."
  value       = length(local.policy_statements)
}

output "cache_cluster_id" {
  description = "OCID of the DEDICATED cache. Answers for AWS elasticache_replication_group_id and _arn. Distinct infrastructure from the platform's shared cache - that separation is the point of the feature, not an implementation detail."
  value       = var.cache_cluster_id
}

output "cache_display_name" {
  description = "Display name of the dedicated cache."
  value       = var.cache_display_name

  precondition {
    condition     = var.cache_display_name == null || can(regex("ratelimiter", var.cache_display_name))
    error_message = "cache_display_name does not contain 'ratelimiter'. This module must be wired to the SECOND oci-cache-valkey unit (name_suffix = \"ratelimiter\"), not to the shared platform cache. Sharing the platform cache would delete the isolation this feature exists for: a failover or maintenance event on the payments session cache would take rate limiting down with it."
  }
}

output "cache_primary_endpoint_address" {
  description = "Private IP of the dedicated cache's primary endpoint. AWS: elasticache_primary_endpoint_address."
  value       = var.cache_primary_endpoint_ip_address
}

output "cache_reader_endpoint_address" {
  description = "Private IP of the dedicated cache's reader endpoint. AWS: elasticache_reader_endpoint_address."
  value       = var.cache_replicas_endpoint_ip_address
}

output "cache_port" {
  description = "Port. Constant 6379; OCI Cache exposes no port argument or attribute."
  value       = var.cache_port
}

output "cache_nsg_id" {
  description = "NSG governing reachability of the dedicated cache. Consumed by the security-last rules unit, which writes the rate limiter's ingress rule into it. Replaces AWS elasticache_security_group_id; note the OCI NSG is owned by the cache module, not by this one."
  value       = var.cache_nsg_id
}

output "cache_connection_info" {
  description = "Everything a consumer needs to connect to the dedicated cache. `tls_required` is hardcoded true and is NOT a reflection of configuration: OCI Cache accepts TLS only and offers no off switch, the opposite of the AWS module's transit_encryption_enabled = false. A client that cannot negotiate TLS gets a connection reset, not a plaintext fallback."
  value       = local.cache_connection_info
}

output "cache_enabled" {
  description = "Whether a dedicated cache is wired in. Replaces the AWS `elasticache_enabled` flag. False means either the sibling unit has not been applied or this module was instantiated without it - the second is a configuration error, since every AWS live root sets elasticache_config.enabled = true."
  value       = local.cache_configured
}

output "region" {
  description = "Region identifier."
  value       = var.region
}
