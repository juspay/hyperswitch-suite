# Card vault (locker) — DATA TIER AND IDENTITY ONLY.
#
# The locker deploys as a workload on GKE through the same GitOps/Helm flow as
# every other application in the cluster. Terraform's job here is only what
# Kubernetes cannot create for itself: the vault's own database, the identity
# its pod assumes, and the CMEK key both depend on.
#
# `composition/locker` was rewritten for this — it no longer provisions a VM
# fleet from a baked image, so this unit needs no `custom_images` entry.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_id                        = "projects/mock/global/networks/mock-vpc"
    private_service_access_range_name = "mock-psa-range"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "gke" {
  config_path = "../application-stack/gke"

  mock_outputs = {
    cluster_name   = "mock-cluster"
    location       = "mock-region"
    endpoint       = "mock-endpoint"
    ca_certificate = "bW9jaw=="
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/locker?ref=gcp-locker-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  # ---------------------------------------------------------------------------
  # Identity
  # ---------------------------------------------------------------------------
  cluster_name     = dependency.gke.outputs.cluster_name
  cluster_location = dependency.gke.outputs.location

  # Required to configure the module's own `kubernetes` provider.
  cluster_endpoint       = dependency.gke.outputs.endpoint
  cluster_ca_certificate = dependency.gke.outputs.ca_certificate

  # These two are fixed by the chart, not by the environment. The
  # hyperswitch-card-vault subchart HARDCODES the ServiceAccount name
  # `hyperswitch-vault-role` in its templates/sa.yaml and the same name as
  # serviceAccountName in its deployment.yaml, with no
  # `serviceAccount.create: false` toggle — so the GSA binding must target
  # exactly this name in the hyperswitch release namespace.
  k8s_namespace            = "hyperswitch"
  k8s_service_account_name = "hyperswitch-vault-role"

  # Helm owns the ServiceAccount object; Terraform must not create a second
  # one. The module creates only the GSA and the workloadIdentityUser binding.
  use_existing_k8s_sa = true

  # FALSE deliberately — this leaves ONE MANUAL STEP.
  #
  # The upstream workload-identity module annotates an existing KSA by
  # shelling out to `gcloud container clusters get-credentials` + `kubectl
  # annotate` as a local-exec at apply time. Against a private cluster with
  # master_authorized_networks, that fails on any runner without a working
  # tunnel — and it would fail the WHOLE apply, including the database.
  #
  # So the IAM half is done deterministically here, and the annotation is an
  # explicit one-liner run with a working context:
  #
  #   kubectl annotate --overwrite sa -n hyperswitch hyperswitch-vault-role \
  #     iam.gke.io/gcp-service-account=$(terragrunt output -raw service_account_email)
  #
  # WITHOUT IT, Workload Identity does not engage and the pod silently falls
  # back to the node's default service account — it does not error.
  annotate_k8s_sa = false

  # roles/alloydb.client and roles/serviceusage.serviceUsageConsumer are
  # granted unconditionally by the module; the connector needs both.
  additional_project_roles = []

  # ---------------------------------------------------------------------------
  # Dedicated AlloyDB cluster
  # ---------------------------------------------------------------------------
  # Kept separate from ../alloydb (the platform's shared cluster) so card data
  # stays in its own PCI-DSS scope.
  create_database = true

  database_config = {
    network_id         = dependency.vpc.outputs.network_id
    allocated_ip_range = dependency.vpc.outputs.private_service_access_range_name

    availability_type = try(values.locker.availability_type, "ZONAL")
    cpu_count         = try(values.locker.cpu_count, 2)

    # The vault's database holds card data — leave this true anywhere it
    # matters.
    deletion_protection = try(values.locker.deletion_protection, true)

    master_username = "locker_admin"

    # master_password deliberately unset -> composition/alloydb generates one
    # and writes it to Secret Manager, and composition/locker grants the
    # vault's service account accessor on THAT SECRET ONLY.
    secret_manager = {
      create = true
    }
  }

  # ---------------------------------------------------------------------------
  # CMEK
  # ---------------------------------------------------------------------------
  create_kms_key = true
  kms_key_id     = "locker"

  kms_protection_level = try(values.locker.kms_protection_level, "SOFTWARE")
  kms_rotation_period  = "7776000s"

  # TRUE, and do not relax it. The upstream KMS module does not implement this
  # with a lifecycle meta-argument — it ships two crypto-key resources at
  # DIFFERENT STATE ADDRESSES and switches between them on this flag, so
  # flipping it plans a destroy of the live key and a create of a new one.
  # Since the key encrypts the vault's database and its backups, that is
  # destructive even where the guard would allow it.
  kms_prevent_destroy = true

  # Off: the key exists to encrypt the AlloyDB cluster. The vault manages its
  # own data-encryption keys internally, so granting the pod
  # cryptoKeyEncrypterDecrypter would widen its permissions for nothing.
  grant_kms_access = false

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    compliance  = "pci-dss"
    managed_by  = "terraform"
  }
}
