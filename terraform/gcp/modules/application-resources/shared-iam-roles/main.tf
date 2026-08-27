# ============================================================================
# Shared IAM Roles (GCP equivalent of application-resources/shared-policy)
# ============================================================================
# Custom IAM roles shared across multiple application-resources modules,
# mirroring the AWS module's for_each-over-policies IAM policy factory.
# GCP's closest equivalent to a standalone reusable IAM policy is a custom
# role, granted to whichever service accounts need it via
# google_project_iam_member elsewhere.
#
# Usage:
#   module "shared_roles" {
#     source = "../../modules/application-resources/shared-iam-roles"
#
#     project_id = "hyperswitch-dev"
#
#     roles = {
#       s3-read = {
#         title       = "Hyperswitch Storage Reader"
#         description = "Read access to Hyperswitch storage buckets"
#         permissions = ["storage.objects.get", "storage.objects.list"]
#       }
#     }
#   }
# ============================================================================

resource "google_project_iam_custom_role" "this" {
  for_each = var.roles

  project     = var.project_id
  role_id     = replace(each.key, "-", "_")
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
  stage       = try(each.value.stage, "GA")
}
