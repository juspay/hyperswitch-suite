# Federates ONE AWS IAM role into this GCP project, so a CI/CD apply worker
# that runs only in AWS (infra-switch / Atlantis, authenticated via IRSA) can
# run `terragrunt apply` against GCP with no static GCP key anywhere.
#
# Grants GCP project roles DIRECTLY to the federated AWS identity - no service
# account, no impersonation. The stack's root.hcl `provider "google"` blocks
# are untouched: humans keep applying with their own GCP permissions exactly as
# before; the CI/CD worker authenticates as the AWS role, separately.
#
# Sits at the top level, not under application-stack - a Workload Identity Pool
# is a project-wide IAM concern (the roles below span VPC/GKE/Envoy/Squid/
# AlloyDB/Valkey as well as the app tier), not scoped to any single app.
#
# ONE POOL PER PROJECT. The module hardcodes workload_identity_pool_id =
# "infraswitch-aws-pool", so this unit must be instantiated at most once per
# GCP project. Two live trees sharing a project_id share this unit's state -
# that is correct and deliberate, not a collision to "fix".
#
# NOTE ON THE NAME. The unit is `iam-infraswitch-federation` while the module
# is `infraswitch-gcp-federation`. The unit name is load-bearing: it is the
# `path` in the consuming stack, and therefore the state prefix of an already-
# applied deployment. Renaming it strands that state and, because the pool id
# is fixed, the re-apply then fails with ALREADY_EXISTS rather than creating
# anything.
#
# No `dependency` blocks: this unit reads nothing from any other unit, and
# nothing reads from it. It is also the unit that must exist BEFORE the CI/CD
# worker can apply any of the others, since it is what grants the roles those
# applies need - so on a green-field rebuild a human applies this one first, as
# themselves.
#
# See the module's README (terraform/gcp/modules/application-resources/
# infraswitch-gcp-federation) for the one-time manual
# `gcloud iam workload-identity-pools create-cred-config` bootstrap step this
# unit's outputs feed into.
#
# OPERATIONAL GOTCHA: destroying this unit SOFT-deletes the pool and provider.
# GCP reserves both ids for 30 days, so a later re-apply fails with
# `Error 409: Requested entity already exists`. Recover with
# `gcloud iam workload-identity-pools undelete` AND
# `... providers undelete` (the provider is soft-deleted separately - the pool
# undelete does not restore it), then `terraform import` both.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/application-resources/infraswitch-gcp-federation?ref=gcp-apps-infraswitch-gcp-federation-v0.1.0"
}

inputs = {
  project_id = include.root.locals.project_id

  # Which AWS identity the pool trusts. Required - there is no sane default,
  # and a wrong value here silently federates the wrong role.
  aws_account_id = values.aws_account_id
  aws_role_name  = values.aws_role_name

  # The module's own defaults, plus five roles a full live tree needs that the
  # defaults do not cover:
  #
  #   dns.admin                            vpc-network manages private Cloud
  #                                        DNS zones (Private Service Connect
  #                                        to Google APIs) via
  #                                        google_dns_managed_zone.
  #   resourcemanager.projectIamAdmin      every apps/* unit grants project
  #                                        roles to its own service account.
  #   artifactregistry.admin               the artifact-registry unit.
  #   networkconnectivity.consumerNetworkAdmin
  #   memorystore.admin                    memorystore-valkey (the Memorystore
  #                                        for Valkey API is distinct from the
  #                                        redis.admin the defaults grant).
  #
  # A `values` knob rather than a literal so an environment can narrow the
  # grant without forking the unit - but narrowing below this set breaks
  # `terragrunt apply` for the units named above.
  project_roles = try(values.project_roles, [
    "roles/compute.admin",
    "roles/container.admin",
    "roles/alloydb.admin",
    "roles/redis.admin",
    "roles/servicenetworking.networksAdmin",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountAdmin",
    "roles/cloudkms.admin",
    "roles/storage.admin",
    "roles/secretmanager.admin",
    "roles/iam.workloadIdentityPoolAdmin",
    "roles/dns.admin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/artifactregistry.admin",
    "roles/networkconnectivity.consumerNetworkAdmin",
    "roles/memorystore.admin",
  ])
}
