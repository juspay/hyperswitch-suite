# ============================================================================
# Atlantis / infra-switch GCP Federation
# ============================================================================
# Lets infra-switch's AWS-only worker pods (authenticated via IRSA as the
# "atlantis-role" IAM role - see terraform/aws/modules/application-resources/
# atlantis in hyperswitch-infra) run `terragrunt apply` against GCP without
# any static GCP key ever existing:
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
#      infra-switch's terraform calls run as the federated AWS identity
#      itself. This also means the GCP live-tree root.hcl files need no
#      provider-level identity override at all: humans keep applying as
#      themselves with whatever GCP permissions they already have,
#      completely independent of this setup.
#
# Roles are broad predefined GCP roles, not least-privilege custom roles -
# deliberate, to mirror how the existing AWS atlantis-role is scoped
# (ec2:*, eks:*, rds:*, ... per service, not action-by-action).
# ============================================================================

resource "google_iam_workload_identity_pool" "atlantis" {
  project                   = var.project_id
  workload_identity_pool_id = "atlantis-aws-pool"
  display_name              = "Atlantis / infra-switch (AWS)"
  description               = "Federates the sandbox atlantis-role AWS IAM role for infra-switch's terragrunt apply workers"
}

resource "google_iam_workload_identity_pool_provider" "atlantis_aws" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.atlantis.workload_identity_pool_id
  workload_identity_pool_provider_id = "atlantis-aws-provider"
  display_name                       = "atlantis-role (AWS)"
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

resource "google_project_iam_member" "atlantis_roles" {
  for_each = toset(var.project_roles)

  project = var.project_id
  role    = each.value
  member  = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.atlantis.name}/attribute.aws_role/${var.aws_role_name}"
}
