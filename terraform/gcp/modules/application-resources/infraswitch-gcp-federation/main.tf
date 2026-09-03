# Lets an AWS-only CI/CD apply worker run against GCP with no static GCP key:
#
#   1. A Workload Identity Pool + AWS provider trusting only one AWS IAM role,
#      matched on `attribute.aws_role`. Nothing else in that AWS account can
#      use the pool.
#   2. Project IAM roles granted directly to that provider's principalSet - no
#      intermediary service account, no impersonation - so the live tree's
#      provider blocks need no identity override and humans keep applying as
#      themselves.
#
# project_roles defaults to broad predefined roles rather than least-privilege
# custom ones; override it to narrow the grant.

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

  # Defense in depth on top of the IAM bindings below: reject at the
  # pool-provider level, so no other principal in the AWS account can even
  # complete a token exchange.
  attribute_condition = "assertion.arn.startsWith('arn:aws:sts::${var.aws_account_id}:assumed-role/${var.aws_role_name}/')"

  aws {
    account_id = var.aws_account_id
  }
}

# Direct project role grants to the federated AWS identity

resource "google_project_iam_member" "infraswitch_roles" {
  for_each = toset(var.project_roles)

  project = var.project_id
  role    = each.value
  member  = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.infraswitch.name}/attribute.aws_role/${var.aws_role_name}"
}
