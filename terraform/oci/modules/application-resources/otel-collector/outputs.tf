# -----------------------------------------------------------------------------
# Output contract.
#
#   role_arn                          -> NONE. No annotation consumes it.
#   role_name / role_id               -> owned by the shared policy object.
#   account_id                        -> NONE, deliberately not remapped to a
#                                        compartment OCID. Compartments are not
#                                        billing or trust boundaries; a value
#                                        that looks like an account identifier
#                                        and is not one is worse than absence.
#   region                            -> region
#   oidc_enabled                      -> NONE. The equivalent assertion is
#                                        length(authorized_workloads) > 0.
#   assume_role_principals_enabled    -> cross_tenancy_enabled
#   aws_managed_policies_enabled      -> NONE. There are none, and the one in
#                                        use has no IAM counterpart.
#   customer_managed_policies_enabled -> shared_statements_enabled
#   inline_policies_enabled           -> additional_grants_enabled
#   -                                 -> apm_domain_id, apm_data_upload_endpoint,
#                                        apm_data_key_secret_id, log_group_id,
#                                        log_id  (all new; the AWS backend
#                                        needed no configuration at all)
# -----------------------------------------------------------------------------

output "policy_statements" {
  description = <<-EOT
    The collector's IAM half, as normalised sorted statements for the
    environment's shared `oke-workload-identity` object.

    Contains `use metrics` and `use log-content` and NOTHING ABOUT TRACES. A
    statement list mentioning APM means someone reintroduced the
    `AWSXRayDaemonWriteAccess`-has-an-OCI-equivalent mistake; APM ingestion is
    header-authenticated with a data key, and `use apm-domains` governs MANAGING
    domains, not uploading to them.

    Blast radius note: these are write-only telemetry verbs. A statement that
    accidentally omitted `request.principal.service_account` would let any pod
    in the namespace publish metrics - noise and cost, not data exposure. Still
    wrong, but bounded, unlike external-secrets-operator or argocd.
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
    error_message = "A rendered statement is missing one of the four request.principal.* conditions. On OCI that fails open and the API accepts it without error."
  }

  precondition {
    condition     = alltrue([for s in local.policy_statements : !can(regex("apm-domain", s))])
    error_message = "A statement grants an APM resource type. Traces do not go through IAM on OCI: APM ingestion is authenticated by `Authorization: dataKey <key>`, and `use apm-domains` governs managing domains, not uploading to them. Granting it does not make traces work and does widen the identity."
  }
}

output "workload_grants" {
  description = "The same grants in `oke-workload-identity`'s structured shape. Preferred over policy_statements when wiring the shared policy - the canonical renderer cannot forget a condition."
  value       = local.workload_grants
}

output "authorized_workloads" {
  description = "Every (cluster_id, namespace, service_account) tuple authorised. Replaces `cluster_service_accounts`. `length(...) > 0` is the honest replacement for the AWS `oidc_enabled` flag."
  value       = local.authorized_workloads
}

output "statement_count" {
  description = "Statements contributed to the shared policy object. Two per cluster in the default configuration."
  value       = length(local.policy_statements)
}

output "apm_domain_id" {
  description = "OCID of the APM domain traces are exported to, created or passed in. NEW - no AWS counterpart, because X-Ray needed no configuration."
  value       = local.effective_apm_domain_id
}

output "apm_data_upload_endpoint" {
  description = "Regional data upload endpoint of the created APM domain. The collector's OTLP exporter posts to <endpoint>/20200101/opentelemetry/private/v1/traces. Null when the domain was passed in rather than created - read it from the existing domain in that case. NOTE the domain is REGIONAL while compartments are global: a cluster exporting to a domain in another region cross-region-egresses every span."
  value       = one(oci_apm_apm_domain.this[*].data_upload_endpoint)
}

output "apm_data_key_secret_id" {
  description = "OCID of the VAULT SECRET holding the APM private data key - never the key itself. This module does not read `data \"oci_apm_data_keys\"`, because doing so would write the key to Terraform state in plaintext. Delivered into the monitoring namespace by external-secrets-operator, which is why this module is ordered after it inside phase 3."
  value       = var.apm_data_key_secret_id
}

output "log_group_id" {
  description = "OCID of the log group the collector pushes into, created or passed in. NEW: `use log-content` grants the verb, but a push needs a target."
  value       = local.effective_log_group_id
}

output "log_id" {
  description = "OCID of the created CUSTOM log. Null when create_log_group is false."
  value       = one(oci_logging_log.collector[*].id)
}

output "region" {
  description = "Region identifier. Unchanged from AWS."
  value       = var.region
}

output "cross_tenancy_enabled" {
  description = "Replaces `assume_role_principals_enabled`. Still false everywhere, and still meaningful - it becomes load-bearing only if observability is centralised into a separate tenancy, at which point argocd.md's undocumented cross-tenancy workload principal question is inherited wholesale."
  value       = var.cross_tenancy_enabled
}

output "shared_statements_enabled" {
  description = "Replaces `customer_managed_policies_enabled`."
  value       = length(var.shared_statements) > 0
}

output "additional_grants_enabled" {
  description = "Replaces `inline_policies_enabled`."
  value       = length(var.additional_grants) > 0
}

output "auth_mechanisms" {
  description = <<-EOT
    The two-mechanism split, stated as data so a reviewer cannot miss it:
    which signal authenticates how. This output exists because the single most
    likely porting error is assuming one identity covers all three signals, and
    the failure mode is silent - the collector starts, accepts OTLP, and drops
    every span with a 401.

    Rung-6 smoke test must exercise BOTH paths: a custom metric appearing in OCI
    Monitoring under metrics_namespace (proves workload identity + use metrics),
    and a span appearing in the APM domain (proves the data-key path).
  EOT
  value = {
    metrics = var.enable_metrics_grant ? "workload-identity (use metrics)" : "not granted - metrics are expected to go to APM via OTLP with the data key"
    logs    = var.enable_logs_grant ? "workload-identity (use log-content)" : "not granted"
    traces  = "APM data key header (Authorization: dataKey ...) - NOT IAM, NOT workload identity"
  }
}
