# ============================================================================
# infraswitch-gcp-federation
# ============================================================================
# Lets an AWS-only CI/CD apply worker (e.g. infra-switch, Atlantis, or any
# tool that runs `terraform`/`terragrunt` from a pod/instance authenticated
# via IRSA as a specific AWS IAM role) run against GCP with no static GCP
# key ever existing:
#
#   1. A Workload Identity Pool + AWS provider that trusts ONLY that one AWS
#      IAM role (matched on the stable `attribute.aws_role` attribute, which
#      Google derives from the STS assumed-role ARN with the per-session
#      suffix stripped - see https://cloud.google.com/iam/docs/workload-
#      identity-federation-with-other-clouds). Nothing else in that AWS
#      account can use this pool.
#
#   2. Project IAM roles granted DIRECTLY to that pool-provider's
#      principalSet - no intermediary service account, no impersonation.
#      The apply worker's terraform calls run as the federated AWS identity
#      itself. This means your GCP live-tree provider blocks need no
#      identity override at all: humans keep applying as themselves with
#      whatever GCP permissions they already have, completely independent
#      of this setup.
#
# Roles default to broad predefined GCP roles, not least-privilege custom
# roles - deliberate, to mirror how a typical CI/CD apply role is scoped on
# the AWS side too (wildcard per service, not action-by-action). Override
# `project_roles` to narrow this for your own use case.
# ============================================================================

resource "google_iam_workload_identity_pool" "infraswitch" {
  project                   = var.project_id
  workload_identity_pool_id = "infraswitch-aws-pool"
  display_name              = var.pool_display_name
  description               = var.pool_description
}

resource "google_iam_workload_identity_pool_provider" "infraswitch_aws" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.infraswitch.workload_identity_pool_id
  workload_identity_pool_provider_id = "infraswitch-aws-provider"
  display_name                       = "${var.aws_role_name} (AWS)"
  description                        = "AWS account ${var.aws_account_id}, role ${var.aws_role_name} only"

  attribute_mapping = {
    "google.subject"     = "assertion.arn"
    "attribute.aws_role" = "assertion.arn.extract('assumed-role/{role}/')"
  }

  # Defense in depth on top of the IAM bindings below, which already scope
  # to attribute.aws_role == var.aws_role_name: reject at the pool-provider
  # level so no other principal in this AWS account can even complete a
  # token exchange against this provider.
  attribute_condition = "assertion.arn.startsWith('arn:aws:sts::${var.aws_account_id}:assumed-role/${var.aws_role_name}/')"

  aws {
    account_id = var.aws_account_id
  }
}

# ============================================================================
# Direct project role grants to the federated AWS identity
# ============================================================================

resource "google_project_iam_member" "infraswitch_roles" {
  for_each = toset(var.project_roles)

  project = var.project_id
  role    = each.value
  member  = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.infraswitch.name}/attribute.aws_role/${var.aws_role_name}"
}
