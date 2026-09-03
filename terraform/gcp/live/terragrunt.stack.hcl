# =============================================================================
# GCP live layer
# =============================================================================
# Generates the internal GCP environments from
# terraform/gcp/catalog/stacks/internal. Each `stack` block below renders into
# terraform/gcp/live/<env>/<region>/ via `terragrunt stack generate` — that
# generated tree is committed (run it again and `git diff` after editing any
# value here).
#
# This is the ONLY file in terraform/gcp/live/ that is edited by hand.
#
# `source` is a plain relative path here, but the unit sources inside the
# stack use get_repo_root() — a relative unit source loses its resolution
# context once the stack is copied into the generated tree.
#
# Values marked REPLACE_ME cannot be committed to this repo
# (scripts/ci/check-sensitive.sh gates exactly that class of value) and must
# be filled in before `terragrunt run-all plan` will succeed. `terragrunt
# stack generate` itself only renders files; it does not evaluate unit inputs,
# so a clean generate says nothing about whether plan works.
# =============================================================================

stack "sandbox" {
  source = "../catalog/stacks/internal"
  path   = "sandbox/asia-south1"

  no_dot_terragrunt_stack = true

  values = {
    # ---------------------------------------------------------------------
    # Identity and state
    # ---------------------------------------------------------------------
    env        = "sandbox"
    region     = "asia-south1"
    project_id = "REPLACE_ME-gcp-project"

    # Terragrunt creates this bucket on the first unit's `init`. Must be
    # globally unique; set skip_bucket_creation = true to use one that is
    # managed elsewhere.
    state_bucket = "REPLACE_ME-sandbox-asia-south1-tfstate"

    # ---------------------------------------------------------------------
    # Networking
    # ---------------------------------------------------------------------
    vpc_cidr_prefix                   = "10.64"
    gke_pods_secondary_range_cidr     = "10.68.0.0/14"
    gke_services_secondary_range_cidr = "10.72.0.0/20"

    # Office / VPN CIDRs allowed to reach the GKE control plane. REQUIRED —
    # left empty, the gke unit falls back to an allow-all placeholder that
    # is not safe to apply.
    vpn_cidr_blocks = [] # REPLACE_ME

    # ---------------------------------------------------------------------
    # DNS
    # ---------------------------------------------------------------------
    domains = {
      api     = "api.sandbox.example.com"     # REPLACE_ME
      grafana = "grafana.sandbox.example.com" # REPLACE_ME
    }

    # ---------------------------------------------------------------------
    # Custom GCE images
    # ---------------------------------------------------------------------
    # These modules are VM ports of the AWS AMI-based originals and need
    # pre-baked images. terraform/gcp/packer/ currently covers envoy and
    # squid only — the rest have no image-build pipeline yet.
    custom_images = {
      envoy             = "REPLACE_ME-envoy"             # packer: terraform/gcp/packer/envoy-proxy
      squid             = "REPLACE_ME-squid"             # packer: terraform/gcp/packer/squid-proxy
      locker            = "REPLACE_ME-locker"            # no packer definition yet
      kafka_broker      = "REPLACE_ME-kafka-broker"      # no packer definition yet
      kafka_controller  = "REPLACE_ME-kafka-controller"  # no packer definition yet
      cassandra         = "REPLACE_ME-cassandra"         # no packer definition yet
      clickhouse_server = "REPLACE_ME-clickhouse-server" # no packer definition yet
      clickhouse_keeper = "REPLACE_ME-clickhouse-keeper" # no packer definition yet
      opensearch        = "REPLACE_ME-opensearch"        # no packer definition yet
    }

    # ---------------------------------------------------------------------
    # Sizing
    # ---------------------------------------------------------------------
    machine_types = {
      gke_system_pool     = "e2-standard-4"
      gke_generic_compute = "e2-standard-4"
      bastion             = "e2-small"
    }

    # ---------------------------------------------------------------------
    # Access and alerting
    # ---------------------------------------------------------------------
    # Group(s) or user(s) granted IAP SSH to the bastion host.
    bastion_iap_members = ["group:REPLACE_ME@example.com"]

    # On-call notification channel for cloud-monitoring alert policies.
    alert_notification_email = "REPLACE_ME@example.com"

    # Secret Manager secret ID holding SMTP credentials — GCP has no SES
    # equivalent, so hyperswitch and decision-engine take one directly.
    # null disables outbound mail wiring in both.
    smtp_secret_id = null
  }
}

# =============================================================================
# Adopting an already-applied environment
# =============================================================================
# The block below is the shape a `dev` environment would take. It is commented
# out because adopting an environment that was applied outside this catalog is
# not a generate-and-apply operation — see terraform/gcp/live/README.md.
#
# Note `project_name`: the catalog defaults to the shortened "hyps" to stay
# under GCP's 30-character service-account ID limit. An environment whose
# resources were already created with a different prefix MUST override it
# here, or the first apply renames or recreates essentially everything.
# =============================================================================

# stack "dev" {
#   source = "../catalog/stacks/internal"
#   path   = "dev/asia-south1"
#
#   no_dot_terragrunt_stack = true
#
#   values = {
#     env          = "dev"
#     region       = "asia-south1"
#     project_id   = "REPLACE_ME-gcp-project"
#     project_name = "REPLACE_ME" # must match what is already applied
#     state_bucket = "REPLACE_ME-dev-asia-south1-tfstate"
#
#     skip_bucket_creation = true # bucket already exists
#
#     vpc_cidr_prefix                   = "10.0"
#     gke_pods_secondary_range_cidr     = "10.4.0.0/14"
#     gke_services_secondary_range_cidr = "10.8.0.0/20"
#
#     vpn_cidr_blocks = [] # REPLACE_ME
#
#     domains = {
#       api     = "api.dev.example.com"     # REPLACE_ME
#       grafana = "grafana.dev.example.com" # REPLACE_ME
#     }
#
#     custom_images = {
#       envoy             = "REPLACE_ME-envoy"
#       squid             = "REPLACE_ME-squid"
#       locker            = "REPLACE_ME-locker"
#       kafka_broker      = "REPLACE_ME-kafka-broker"
#       kafka_controller  = "REPLACE_ME-kafka-controller"
#       cassandra         = "REPLACE_ME-cassandra"
#       clickhouse_server = "REPLACE_ME-clickhouse-server"
#       clickhouse_keeper = "REPLACE_ME-clickhouse-keeper"
#       opensearch        = "REPLACE_ME-opensearch"
#     }
#
#     machine_types = {
#       gke_system_pool     = "e2-standard-4"
#       gke_generic_compute = "e2-standard-4"
#       bastion             = "e2-small"
#     }
#
#     bastion_iap_members      = ["group:REPLACE_ME@example.com"]
#     alert_notification_email = "REPLACE_ME@example.com"
#     smtp_secret_id           = null
#   }
# }
