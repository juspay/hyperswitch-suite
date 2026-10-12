# Output contract. AWS's policy_arns / policy_names are replaced by statement
# text (nothing is attachable). This module creates NO OCI resources.

output "policy_statements" {
  description = <<-EOT
    Every shared grant, rendered as normalised, sorted `oci_identity_policy`
    statement strings, ready to concatenate into the environment's single
    shared `oke-workload-identity` policy object.

    Replaces AWS `policy_arns`. This is TEXT, not an object reference: there is
    nothing to attach and nothing to detach. Revoking a shared grant is an edit
    to every policy object that embedded it - one code change here, but N plans
    and N applies downstream. Write that into the runbook.
  EOT
  value       = local.policy_statements

  precondition {
    condition = alltrue([
      for s in local.policy_statements :
      can(regex("request\\.principal\\.type='workload'", s))
      && can(regex("request\\.principal\\.namespace='[^']+'", s))
      && can(regex("request\\.principal\\.service_account='[^']+'", s))
      && can(regex("request\\.principal\\.cluster_id='[^']+'", s))
    ])
    error_message = "A rendered statement is missing one of the four request.principal.* conditions. On OCI that fails OPEN - a missing cluster_id grants every cluster in the tenancy, a missing service_account grants every pod in the namespace. This is a renderer bug, not a configuration error."
  }
}

output "statements_by_grant" {
  description = "The same statements keyed by logical grant name, so a reviewer can answer 'what does file_uploads actually grant, and to whom' without parsing the flat list. The AWS analogue is reading one aws_iam_policy document."
  value       = local.statements_by_grant
}

output "workload_grants" {
  description = <<-EOT
    The same grants in `oke-workload-identity`'s STRUCTURED input shape, one
    entry per (grant x subject) - cluster expansion is that module's job.

    PREFER THIS over `policy_statements` when wiring into the shared policy:
    the canonical renderer cannot forget a `where` condition, and on OCI a
    forgotten condition fails open.
  EOT
  value       = local.workload_grants
}

output "authorized_workloads" {
  description = "Every (cluster_id, namespace, service_account) tuple these shared grants authorise. Audit surface; the AWS analogue was the attachment listing."
  value       = local.authorized_workloads
}

output "statement_count" {
  description = "How many statements these shared grants cost the consuming policy object. Watch it: the per-object cap is 50 and the per-compartment-hierarchy cap is 500, documented as a hard limit that cannot be increased. A shared grant costs one statement per (subject x cluster), where on AWS it cost one attachment."
  value       = length(local.policy_statements)
}

output "grant_names" {
  description = "Logical grant names rendered by this module. Intended for the consuming policy object's freeform_tags (e.g. shared_grants = join(\",\", ...)) so the AWS question 'who has this shared policy?' stays answerable by tag query rather than text search."
  value       = sort(keys(var.grants))
}
