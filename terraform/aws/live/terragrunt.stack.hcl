# =============================================================================
# Internal live layer
# =============================================================================
# Generates the internal pre-prod / prod environments from
# terraform/aws/catalog/stacks/internal. Each `stack` block below renders into
# terraform/aws/live/<env>/<region>/ via `terragrunt stack generate` — that
# generated tree is committed (run it again and `git diff` after editing any
# value here).
#
# `account_id`, `admin_role_arn`, `ami_id` and friends are REPLACE_ME
# placeholders — real values can't be committed (see
# scripts/ci/check-sensitive.sh) and must be filled in out-of-band before
# `terragrunt run-all plan` will succeed. `terragrunt stack generate` itself
# only renders files; it does not evaluate unit inputs.
#
# NOTE: the self-host generator (scripts/self-host/generate.sh) also writes a
# terragrunt.stack.hcl under terraform/aws/live/<env>/ in a merchant's fork,
# defaulting to env "prod". Any fork that runs the generator without first
# removing this file's "prod" block will collide with it.
# =============================================================================

# stack "dev" {
#   source = "../catalog/stacks/internal"
#   path   = "dev/eu-central-1"

#   no_dot_terragrunt_stack = true

#   values = {
#     env          = "dev"
#     region       = "eu-central-1"
#     region_code  = "euc1"
#     project_name = "hyperswitch"
#     account_id   = "000000000000" # REPLACE_ME
#     state_bucket = "hyperswitch-tfstate-dev"

#     # Networking
#     vpc_cidr_prefix = "10.10"

#     # DNS / TLS
#     base_domain = "dev.example.com" # REPLACE_ME

#     # Access
#     admin_role_arn     = "arn:aws:iam::000000000000:role/REPLACE_ME" # REPLACE_ME
#     admin_access_cidrs = []

#     # Proxies / bastion — shared AMI placeholder; use a real per-role AMI id.
#     ami_id = "ami-REPLACE_ME"

#     # Envoy ingress domains: map of virtual-host-group => [domains]
#     virtual_hosts_domains = {
#       api = ["api.dev.example.com"] # REPLACE_ME
#     }

#     # Istio host domains (map keys are arbitrary; module reads the values)
#     istio_host_domains = {
#       dev = "istio.internal.staging.euc1.dev.example.com" # REPLACE_ME
#     }

#     # Sizing
#     db_instance_class            = "db.r5.large"
#     db_engine_version            = "17.9"
#     cache_node_type              = "cache.m6g.large"
#     eks_version                  = "1.35"
#     eks_instance_types           = ["t3.xlarge"]
#     eks_ami_id                   = null
#     system_nodes_desired_size    = 1
#     generic_compute_desired_size = 2
#     generic_compute_min_size     = 1
#   }
# }

stack "pre-prod" {
  source = "../catalog/stacks/internal"
  path   = "pre-prod/eu-central-1"

  no_dot_terragrunt_stack = true

  values = {
    env          = "pre-prod"
    region       = "eu-central-1"
    region_code  = "euc1"
    project_name = "hyperswitch"
    account_id   = "000000000000" # REPLACE_ME
    state_bucket = "hyperswitch-tfstate-pre-prod"

    vpc_cidr_prefix = "10.20"

    base_domain = "preprod.example.com" # REPLACE_ME

    admin_role_arn     = "arn:aws:iam::000000000000:role/REPLACE_ME" # REPLACE_ME
    admin_access_cidrs = []

    ami_id = "ami-REPLACE_ME"

    virtual_hosts_domains = {
      api = ["api.preprod.example.com"] # REPLACE_ME
    }

    istio_host_domains = {
      preprod = "istio.internal.staging.euc1.preprod.example.com" # REPLACE_ME
    }

    db_instance_class            = "db.r5.xlarge"
    db_engine_version            = "17.9"
    cache_node_type              = "cache.m6g.large"
    eks_version                  = "1.35"
    eks_instance_types           = ["t3.xlarge"]
    eks_ami_id                   = null
    system_nodes_desired_size    = 2
    generic_compute_desired_size = 2
    generic_compute_min_size     = 2
  }
}

stack "prod" {
  source = "../catalog/stacks/internal"
  path   = "prod/eu-central-1"

  no_dot_terragrunt_stack = true

  values = {
    env          = "prod"
    region       = "eu-central-1"
    region_code  = "euc1"
    project_name = "hyperswitch"
    account_id   = "000000000000" # REPLACE_ME
    state_bucket = "hyperswitch-tfstate-prod"

    vpc_cidr_prefix = "10.30"

    base_domain = "example.com" # REPLACE_ME

    admin_role_arn     = "arn:aws:iam::000000000000:role/REPLACE_ME" # REPLACE_ME
    admin_access_cidrs = []

    ami_id = "ami-REPLACE_ME"

    virtual_hosts_domains = {
      api = ["api.example.com"] # REPLACE_ME
    }

    istio_host_domains = {
      prod = "istio.internal.prod.euc1.example.com" # REPLACE_ME
    }

    db_instance_class            = "db.r6g.xlarge"
    db_engine_version            = "17.9"
    cache_node_type              = "cache.m6g.xlarge"
    eks_version                  = "1.35"
    eks_instance_types           = ["m6i.xlarge"]
    eks_ami_id                   = null
    system_nodes_desired_size    = 2
    generic_compute_desired_size = 3
    generic_compute_min_size     = 3
  }
}
