# ============================================================================
# Artifact Registry (GCP equivalent of composition/ecr)
# ============================================================================
# Creates one Docker-format Artifact Registry repository per entry in
# var.repositories, mirroring the AWS ecr module's for_each-over-repos shape.
# Repository-level IAM is granted directly (repositories are the natural
# permission boundary on Artifact Registry, unlike ECR's account-wide policy
# style).
#
# Usage:
#   module "artifact_registry" {
#     source = "../../modules/composition/artifact-registry"
#
#     project_id  = "hyperswitch-dev"
#     environment = "dev"
#     location    = "europe-west1"
#
#     repositories = {
#       hyperswitch = {
#         cleanup_policies = { keep-recent = { action = "KEEP", most_recent_versions = 10 } }
#       }
#     }
#   }
# ============================================================================

resource "google_artifact_registry_repository" "this" {
  for_each = var.repositories

  project       = var.project_id
  location      = var.location
  repository_id = each.key
  description   = try(each.value.description, "Hyperswitch ${each.key} repository")
  format        = try(each.value.format, "DOCKER")
  mode          = try(each.value.mode, "STANDARD_REPOSITORY")

  kms_key_name = try(each.value.kms_key_name, null)

  dynamic "docker_config" {
    for_each = try(each.value.immutable_tags, false) ? [1] : []
    content {
      immutable_tags = true
    }
  }

  dynamic "cleanup_policies" {
    for_each = try(each.value.cleanup_policies, {})
    content {
      id     = cleanup_policies.key
      action = try(cleanup_policies.value.action, "DELETE")

      dynamic "condition" {
        for_each = try(cleanup_policies.value.action, "DELETE") != "KEEP" ? [try(cleanup_policies.value.condition, {})] : []
        content {
          tag_state             = try(condition.value.tag_state, "ANY")
          tag_prefixes          = try(condition.value.tag_prefixes, null)
          version_name_prefixes = try(condition.value.version_name_prefixes, null)
          package_name_prefixes = try(condition.value.package_name_prefixes, null)
          older_than            = try(condition.value.older_than, null)
        }
      }

      dynamic "most_recent_versions" {
        for_each = try(cleanup_policies.value.action, "DELETE") == "KEEP" ? [try(cleanup_policies.value, {})] : []
        content {
          package_name_prefixes = try(most_recent_versions.value.package_name_prefixes, null)
          keep_count            = try(most_recent_versions.value.most_recent_versions, 10)
        }
      }
    }
  }

  labels = merge(local.common_labels, try(each.value.labels, {}))
}

# ==============================================================================
# Repository IAM bindings
# ==============================================================================
resource "google_artifact_registry_repository_iam_member" "this" {
  for_each = local.repository_iam_flat

  project    = var.project_id
  location   = var.location
  repository = each.value.repository
  role       = each.value.role
  member     = each.value.member
}
