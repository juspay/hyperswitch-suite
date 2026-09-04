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
# `source` is a plain relative path here, but the unit sources inside the stack
# use get_repo_root() — a relative unit source loses its resolution context
# once the stack is copied into the generated tree.
#
# Values marked REPLACE_ME cannot be committed to this repo
# (scripts/ci/check-sensitive.sh gates exactly that class of value) and must be
# filled in before `terragrunt run-all plan` will succeed. `terragrunt stack
# generate` itself only renders files; it does not evaluate unit inputs, so a
# clean generate says nothing about whether plan works.
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
    # left empty, the gke unit falls back to an allow-all placeholder that is
    # not safe to apply.
    vpn_cidr_blocks = [] # REPLACE_ME

    # ---------------------------------------------------------------------
    # DNS
    # ---------------------------------------------------------------------
    domains = {
      api     = "api.sandbox.example.com"     # REPLACE_ME
      grafana = "grafana.sandbox.example.com" # REPLACE_ME
    }

    # ---------------------------------------------------------------------
    # Custom GCE images — edge proxies
    # ---------------------------------------------------------------------
    # Pre-baked images built from terraform/gcp/packer/{envoy-proxy,squid-proxy}.
    # Image names only; the units expand them to a full projects/<id>/global/
    # images/<name> path against project_id above.
    custom_images = {
      envoy = "REPLACE_ME-envoy"
      squid = "REPLACE_ME-squid"
    }

    # ---------------------------------------------------------------------
    # Cluster sizing
    # ---------------------------------------------------------------------
    machine_types = {
      gke_system_pool     = "e2-standard-4"
      gke_generic_compute = "e2-standard-4"
      bastion             = "e2-small"
    }

    # Group(s) or user(s) granted IAP SSH to the bastion host.
    bastion_iap_members = ["group:REPLACE_ME@example.com"]

    # ---------------------------------------------------------------------
    # Data services — every key optional; omit the block for unit defaults
    # ---------------------------------------------------------------------
    # Defaults are dev-shaped. Production wants availability_type = "REGIONAL"
    # plus at least one read pool.
    alloydb = {
      availability_type   = "ZONAL"
      cpu_count           = 2
      read_pool_instances = {}
      deletion_protection = true
    }

    valkey = {
      shard_count                 = 1
      replica_count               = 1
      node_type                   = "SHARED_CORE_NANO"
      deletion_protection_enabled = true
    }

    # The card vault's own AlloyDB cluster, separate from the shared one above
    # so card data stays in its own PCI-DSS scope. Production wants
    # availability_type = "REGIONAL" and deletion_protection left true.
    locker = {
      availability_type    = "ZONAL"
      cpu_count            = 2
      deletion_protection  = true
      kms_protection_level = "SOFTWARE"
    }

    # ---------------------------------------------------------------------
    # Application
    # ---------------------------------------------------------------------
    # Secret Manager secret ID holding SMTP credentials — GCP has no SES
    # equivalent, so hyperswitch takes one directly. null disables outbound
    # mail wiring.
    smtp_secret_id = null
  }
}

# =============================================================================
# dev / asia-south1 — the already-applied environment
# =============================================================================
# Values below reproduce the LIVE dev environment, not a greenfield default.
# Three things make it different from the sandbox block above, and all three
# are load-bearing:
#
#   1. project_name = "hyperswitch", not the catalog default "hyps". Every
#      live dev resource carries the long prefix. Changing it renames or
#      recreates essentially the whole environment.
#   2. subnet_cidrs pins all 12 tiers. dev's addressing was hand-allocated and
#      does NOT follow the vpc_cidr_prefix formula — the formula would put
#      external-incoming at 10.2.0.0/24 where it actually lives at
#      10.2.64.0/24, and so on for every tier.
#   3. network_options pins the NAT / PSC / default-deny settings dev already
#      runs, which differ from the unit's greenfield defaults.
#
# vpn_cidr_blocks and bastion_iap_members are documentation-range and
# example.com placeholders here, matching the sanitised dev tree already in
# this repo (#312) — scripts/ci/check-sensitive.sh blocks the real values.
# Substitute the real ones out-of-band before planning against dev.
#
# NOT SAFE TO APPLY YET. This generates a tree; it does not reconcile with
# dev's existing state. See terraform/gcp/live/README.md.
# =============================================================================

stack "dev" {
  source = "../catalog/stacks/internal"
  path   = "dev/asia-south1"

  no_dot_terragrunt_stack = true

  values = {
    env          = "dev"
    region       = "asia-south1"
    project_id   = "hyperswitch-dev"
    project_name = "hyperswitch" # MUST match what is already applied

    state_bucket         = "hyperswitch-dev-asia-south1-terraform-state"
    skip_bucket_creation = false

    # -----------------------------------------------------------------------
    # Networking — pinned to what is live, not derived
    # -----------------------------------------------------------------------
    vpc_cidr_prefix                   = "10.2"
    gke_pods_secondary_range_cidr     = "10.100.0.0/16"
    gke_services_secondary_range_cidr = "10.101.0.0/20"

    subnet_cidrs = {
      external_incoming    = "10.2.64.0/24"
      management           = "10.2.67.0/24"
      gke_nodes            = "10.2.32.0/20"
      database             = "10.2.73.0/24"
      memorystore          = "10.2.74.0/24"
      locker_database      = "10.2.75.0/24"
      locker_server        = "10.2.76.0/24"
      outgoing_proxy       = "10.2.77.0/24"
      data_stack           = "10.2.80.0/24"
      serverless_connector = "10.2.90.0/28"
    }

    network_options = {
      network_name = "hyperswitch-dev-vpc"

      # Egress leaves through the squid proxy tier only.
      nat_subnetwork_tiers = ["outgoing-proxy"]
      nat_log_filter       = "ALL"

      enable_psc_google_apis      = true
      enable_default_deny_ingress = true
      enable_default_deny_egress  = true

      # `psa` is what permits egress to the AlloyDB clusters.
      vpc_internal_ranges = {
        primary  = "10.2.0.0/16"
        gke_pods = "10.100.0.0/16"
        gke_svcs = "10.101.0.0/20"
        psa      = "10.214.0.0/16"
      }
    }

    # Paired { cidr_block, display_name } — do not flatten. PLACEHOLDERS.
    vpn_cidr_blocks = [
      { cidr_block = "198.51.100.0/30", display_name = "office" }, # REPLACE_ME
      { cidr_block = "203.0.113.10/32", display_name = "vpn" },    # REPLACE_ME
      { cidr_block = "10.2.67.0/24", display_name = "management-subnet-bastion" },
    ]

    # -----------------------------------------------------------------------
    # Cluster
    # -----------------------------------------------------------------------
    gke_master_ipv4_cidr_block = "172.16.0.0/28"
    gke_deletion_protection    = false

    machine_types = {
      gke_system_pool     = "e2-standard-2"
      gke_generic_compute = "e2-standard-2"
      bastion             = "e2-small"
    }

    bastion_iap_members = ["group:platform-team@example.com"] # REPLACE_ME

    # -----------------------------------------------------------------------
    # DNS
    # -----------------------------------------------------------------------
    domains = {
      api     = "dev.hyperswitch.internal"
      grafana = "dev.hyperswitch.internal"
    }

    # -----------------------------------------------------------------------
    # Edge proxy images
    # -----------------------------------------------------------------------
    # Expanded by the units to projects/<project_id>/global/images/<value>, so
    # an image family is expressed as "family/<name>".
    custom_images = {
      envoy = "hyperswitch-envoy-dev-20260820032919"
      squid = "family/hyperswitch-squid-dev"
    }

    # -----------------------------------------------------------------------
    # Data services
    # -----------------------------------------------------------------------
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

    locker = {
      availability_type    = "ZONAL"
      cpu_count            = 2
      deletion_protection  = false
      kms_protection_level = "SOFTWARE"
    }

    smtp_secret_id = null
  }
}
