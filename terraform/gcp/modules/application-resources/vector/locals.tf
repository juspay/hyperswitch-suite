locals {
  gcp_sa_name = "${var.project_name}-${var.environment}-vector-sa"

  name_prefix = "${var.environment}-${var.project_name}-vector"

  # GCS bucket names are global: the same name in two projects collides, so default names carry a
  # suffix (var.bucket_name_suffix; null = first 6 hex of sha256(project_id), "" = none). Names are
  # capped at 63 characters by trimming only the readable prefix - the role and the suffix always
  # survive, so two buckets of one module can never trim to the same name - and a trailing -/_/.
  # is stripped because bucket names must end with a letter or digit.
  bucket_suffix     = var.bucket_name_suffix != null ? var.bucket_name_suffix : substr(sha256(var.project_id), 0, 6)
  bucket_suffix_sep = local.bucket_suffix == "" ? "" : "-${local.bucket_suffix}"
  bucket_names = {
    for role in ["logs"] : role => "${trim(substr(local.name_prefix, 0, 63 - length(role) - 1 - length(local.bucket_suffix_sep)), "-_.")}-${role}${local.bucket_suffix_sep}"
  }

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "application" = "vector"
    },
    var.labels
  )

  bucket_name = var.bucket_name != null ? var.bucket_name : local.bucket_names["logs"]
}
