# =============================================================================
# AWS live layer
# =============================================================================
# Generates the dev environment from terraform/aws/catalog/stacks/dev, pinned
# to the stack/aws/catalog-v0.1.0 tag — the immutable release boundary for the
# whole stack, same grammar as the unit tags the stack itself consumes. The
# `stack` block below renders into terraform/aws/live/dev/<region>/ via
# `terragrunt stack generate` — that generated tree is committed (run it again
# and `git diff` after editing any value here). Bump the ref to roll every
# unit in the stack forward at once.
#
# This is the ONLY file in terraform/aws/live/ that is edited by hand.
#
# `account_id`, `admin_role_arn`, `ami_id` and friends are REPLACE_ME
# placeholders — real values can't be committed (see
# scripts/ci/check-sensitive.sh) and must be filled in out-of-band before
# `terragrunt run-all plan` will succeed. `terragrunt stack generate` itself
# only renders files; it does not evaluate unit inputs.
# =============================================================================

stack "dev" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/stacks/dev?ref=stack/aws/catalog-v0.1.0"
  path   = "dev/eu-central-1"

  no_dot_terragrunt_stack = true

  values = {
    env          = "dev"
    region       = "eu-central-1"
    region_code  = "euc1"
    project_name = "hyperswitch"
    account_id   = "000000000000" # REPLACE_ME
    state_bucket = "hyperswitch-tfstate-dev"

    # Networking
    vpc_cidr_prefix = "10.10"

    # DNS / TLS
    base_domain = "dev.example.com" # REPLACE_ME

    # Access
    admin_role_arn     = "arn:aws:iam::000000000000:role/REPLACE_ME" # REPLACE_ME
    admin_access_cidrs = []

    # Proxies / bastion — shared AMI placeholder; use a real per-role AMI id.
    ami_id = "ami-REPLACE_ME"

    # Envoy ingress domains: map of virtual-host-group => [domains]
    virtual_hosts_domains = {
      api = ["api.dev.example.com"] # REPLACE_ME
    }

    # Istio host domains (map keys are arbitrary; module reads the values)
    istio_host_domains = {
      dev = "istio.internal.staging.euc1.dev.example.com" # REPLACE_ME
    }

    # Sizing
    db_instance_class            = "db.r5.large"
    db_engine_version            = "17.9"
    cache_node_type              = "cache.m6g.large"
    eks_version                  = "1.35"
    eks_instance_types           = ["t3.xlarge"]
    eks_ami_id                   = null
    system_nodes_desired_size    = 1
    generic_compute_desired_size = 2
    generic_compute_min_size     = 1
  }
}
