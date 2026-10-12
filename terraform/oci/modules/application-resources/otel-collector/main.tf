# -----------------------------------------------------------------------------
# NO `oci_identity_policy`. The identity is `policy_statements` in outputs.tf,
# contributed to the environment's single shared oke-workload-identity object.
#
# What IS here is the half of the job AWS never had to configure: the trace
# backend and the log push target. On AWS, X-Ray and CloudWatch are ambient -
# a managed policy on the role is the entire setup. On OCI both are explicit
# objects, one of them regional, one of them authenticated outside IAM.
# -----------------------------------------------------------------------------

# --- Traces -------------------------------------------------------------------
# APM ingests OTLP spans over HTTP at
#   https://<data_upload_endpoint>/20200101/opentelemetry/private/v1/traces
# authenticated by `Authorization: dataKey <key>`. No principal. No policy. This
# resource produces NO IAM grant, and there is no statement anywhere in this
# module that mentions APM.
#
# Deliberately NOT read here: `data "oci_apm_data_keys"`. It would return the
# private key and write it to Terraform state in plaintext. The key is not an
# attribute of this resource either, which is what makes creating the domain in
# Terraform safe. Place the key into a vault secret out of band and pass its
# OCID as `apm_data_key_secret_id`.
resource "oci_apm_apm_domain" "this" {
  count = var.create_apm_domain ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = coalesce(var.apm_domain_display_name, "${local.name_prefix}-apm")
  description    = "OTLP trace ingestion for the ${var.environment} otel-collector. Authenticated by a private data key, NOT by workload identity."
  is_free_tier   = var.apm_is_free_tier

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    precondition {
      condition     = var.apm_domain_id == null
      error_message = "create_apm_domain is true and apm_domain_id is also set. Pick one: create the domain here, or point at an existing one."
    }
  }
}

# --- Logs ---------------------------------------------------------------------
# `use log-content` grants the verb; a push needs a target. CUSTOM log type,
# because the collector pushes application telemetry rather than an OCI service
# emitting its own logs (which is what log_type = SERVICE plus a `configuration`
# block is for).
resource "oci_logging_log_group" "this" {
  count = var.create_log_group ? 1 : 0

  compartment_id = local.logs_compartment
  display_name   = "${local.name_prefix}-logs"
  description    = "Log group for the ${var.environment} otel-collector's OCI Logging exporter."

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    precondition {
      condition     = var.log_group_id == null
      error_message = "create_log_group is true and log_group_id is also set. Pick one."
    }
  }
}

resource "oci_logging_log" "collector" {
  count = var.create_log_group ? 1 : 0

  display_name       = coalesce(var.log_display_name, "${local.name_prefix}-collector")
  log_group_id       = oci_logging_log_group.this[0].id
  log_type           = "CUSTOM"
  is_enabled         = true
  retention_duration = var.log_retention_duration

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}
