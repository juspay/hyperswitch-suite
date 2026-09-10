# =============================================================================
# GCP live layer
# =============================================================================
# Generates the GCP dev environment from terraform/gcp/catalog/stacks/dev,
# pinned to the stack/gcp/catalog-v0.1.0 tag. This `stack` block renders into
# terraform/gcp/live/dev/asia-south1/ via
# `terragrunt stack generate` — that generated tree is committed (run it again
# and `git diff` after editing any value here).
#
# This is the ONLY file in terraform/gcp/live/ that is edited by hand.
#
# `source` uses a git ref pinned to the stack tag, matching the unit tags the
# stack itself consumes — the tag is the immutable release boundary, and a
# relative path would lose resolution context once the stack is copied into
# the generated tree. Bump the ref to roll every unit in the stack forward at
# once.
#
# Values marked REPLACE_ME cannot be committed to this repo
# (scripts/ci/check-sensitive.sh gates exactly that class of value) and must be
# filled in before `terragrunt run-all plan` will succeed. `terragrunt stack
# generate` itself only renders files; it does not evaluate unit inputs, so a
# clean generate says nothing about whether plan works.
# =============================================================================

stack "dev" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/stacks/dev?ref=stack/gcp/catalog-v0.1.0"
  path   = "dev/asia-south1"

  no_dot_terragrunt_stack = true

  values = {
    # -------------------------------------------------------------------------
    # Identity and state
    # -------------------------------------------------------------------------
    env        = "dev"
    region     = "asia-south1"
    project_id = "REPLACE_ME-gcp-project"

    # Terragrunt creates this bucket on the first unit's `init`. Must be
    # globally unique; set skip_bucket_creation = true to use one that is
    # managed elsewhere.
    state_bucket = "REPLACE_ME-dev-asia-south1-tfstate"

    # -------------------------------------------------------------------------
    # CI/CD identity
    # -------------------------------------------------------------------------
    # The AWS IAM role federated into this GCP project, so an AWS-only apply
    # worker (infra-switch / Atlantis) can run terragrunt here with no static
    # GCP key. Name the role, not its ARN.
    #
    # project_roles is left unset so the unit's own default list applies — that
    # list is what a full live tree needs. Set it here only to deliberately
    # narrow the grant for this environment.
    infraswitch_federation = {
      aws_account_id = "REPLACE_ME-aws-account-id"
      aws_role_name  = "REPLACE_ME-aws-role-name"
    }

    # -------------------------------------------------------------------------
    # Networking
    # -------------------------------------------------------------------------
    vpc_cidr_prefix                   = "10.2"
    gke_pods_secondary_range_cidr     = "10.100.0.0/16"
    gke_services_secondary_range_cidr = "10.101.0.0/20"

    # Office / VPN CIDRs allowed to reach the GKE control plane. REQUIRED —
    # left empty, the gke unit falls back to an allow-all placeholder that is
    # not safe to apply.
    vpn_cidr_blocks = [] # REPLACE_ME

    # -------------------------------------------------------------------------
    # DNS
    # -------------------------------------------------------------------------
    domains = {
      api     = "api.dev.example.com"     # REPLACE_ME
      grafana = "grafana.dev.example.com" # REPLACE_ME
    }

    # -------------------------------------------------------------------------
    # Custom GCE images — edge proxies
    # -------------------------------------------------------------------------
    # Pre-baked images built from terraform/gcp/packer/{envoy-proxy,squid-proxy}.
    # Image names only; the units expand them to a full projects/<id>/global/
    # images/<name> path against project_id above.
    custom_images = {
      envoy = "REPLACE_ME-envoy"
      squid = "REPLACE_ME-squid"
    }

    # -------------------------------------------------------------------------
    # Cluster sizing
    # -------------------------------------------------------------------------
    machine_types = {
      gke_system_pool     = "e2-standard-4"
      gke_generic_compute = "e2-standard-4"
      bastion             = "e2-small"
    }

    # Group(s) or user(s) granted IAP SSH to the bastion host.
    bastion_iap_members = ["group:REPLACE_ME@example.com"]

    # -------------------------------------------------------------------------
    # Data services — every key optional; omit the block for unit defaults
    # -------------------------------------------------------------------------
    # Defaults are dev-shaped. Production wants availability_type = "REGIONAL"
    # plus at least one read pool.
    alloydb = {
      availability_type   = "ZONAL"
      cpu_count           = 2
      read_pool_instances = {}
      deletion_protection = false
    }

    valkey = {
      shard_count                 = 1
      replica_count               = 1
      node_type                   = "SHARED_CORE_NANO"
      deletion_protection_enabled = false
    }

    # The card vault's own AlloyDB cluster, separate from the shared one above
    # so card data stays in its own PCI-DSS scope. Production wants
    # availability_type = "REGIONAL" and deletion_protection left true.
    locker = {
      availability_type    = "ZONAL"
      cpu_count            = 2
      deletion_protection  = false
      kms_protection_level = "SOFTWARE"
    }

    # -------------------------------------------------------------------------
    # Application
    # -------------------------------------------------------------------------
    # Secret Manager secret ID holding SMTP credentials — GCP has no SES
    # equivalent, so hyperswitch takes one directly. null disables outbound
    # mail wiring.
    smtp_secret_id = null
  }
}
