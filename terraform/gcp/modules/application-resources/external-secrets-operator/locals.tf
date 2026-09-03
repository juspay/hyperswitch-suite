locals {
  gcp_sa_name = "${var.project_name}-${var.environment}-eso-sa"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "application" = "external-secrets-operator"
    },
    var.labels
  )

  # Secret Manager's accessor role, granted project-wide or per-secret. The
  # AWS module's inline policy is always project-wide (its resource ARN is
  # `secret:*` across the whole account/region); scoping per-secret is the
  # tighter option GCP makes available, so both are offered here.
  project_roles = concat(
    var.scope_to_project ? ["roles/secretmanager.secretAccessor"] : [],
    var.additional_project_roles,
  )
}
