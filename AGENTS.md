# AGENTS.md — Context for AI Agents

This file provides context for AI agents (OpenCode, Claude Code, Cursor, etc.) working on the hyperswitch-suite repository.

## Project Overview

Hyperswitch is an open-source payments switch. This repository is the **infrastructure-as-code suite** that deploys Hyperswitch on AWS, GCP, OCI and Azure using Terraform and Terragrunt. It also contains load-testing tooling and CI/CD automation.

The repo is organised by cloud under `terraform/`. Maturity differs by cloud: AWS is production-capable with a full live layer; GCP has a dev live layer and is migrating to a tag-pinned catalog/unit pattern; OCI has modules + bootstrap only; Azure has two early composition modules.

> The application source code lives in other repos (see [Related Repositories](#related-repositories)). Do not treat this repo as the payment server.

## Cloud Maturity

| Cloud | Maturity | Live layer | Catalog/Units | Modules | Bootstrap |
|---|---|---|---|---|---|
| AWS | Production-capable | `terraform/aws/live/dev/eu-central-1/` (Terragrunt) | Proposed in PR #302 | 20 base + 26 composition + 14 app-resources + cloudfront-resources | `dev/integ/prod/sandbox` |
| GCP | Dev live + catalog migration | `terraform/gcp/live/dev/asia-south1/` (Terragrunt) | `terraform/gcp/catalog/units/` (19 pinned units) | 16 composition + 10 app-resources + packer | Via GCS backend in live root |
| OCI | Modules + bootstrap only | None in this repo (planned in `hyperswitch-infra`) | None | 22 composition + 13 app-resources + packer | `terraform/oci/bootstrap/dev/` |
| Azure | Early modules only | None | None | 2 composition modules (`vpc-network`, `storage-account-backend`) | None in this repo |

## Repository Structure

```
hyperswitch-suite/
├── terraform/
│   ├── aws/                    # Full AWS deployment suite
│   │   ├── modules/
│   │   │   ├── base/           # Layer 1: Atomic AWS resource modules (20 modules)
│   │   │   ├── composition/    # Layer 2: Service composition modules (26 modules)
│   │   │   ├── application-resources/  # Layer 3: EKS application modules (14 modules)
│   │   │   └── cloudfront-resources/   # Layer 4: Shared CloudFront assets
│   │   ├── live/
│   │   │   └── dev/eu-central-1/       # Terragrunt live environment
│   │   │       ├── vpc-network, eks, database, elasticache, ecr, jump-host
│   │   │       ├── envoy-proxy, squid-proxy, locker, cloudfront, security-rules
│   │   │       └── apps/      # EKS workload deployments
│   │   └── bootstrap/         # S3 + DynamoDB state backend (dev/integ/prod/sandbox)
│   ├── gcp/                   # GCP modules, live dev, and catalog units
│   │   ├── modules/
│   │   │   ├── composition/   # 16 modules
│   │   │   └── application-resources/  # 10 modules
│   │   ├── catalog/units/     # 19 tag-pinned Terragrunt units
│   │   ├── live/dev/asia-south1/      # Hand-written Terragrunt live layer
│   │   └── packer/            # Custom image builders
│   ├── oci/                   # OCI modules + bootstrap (live layer in hyperswitch-infra)
│   │   ├── modules/
│   │   │   ├── composition/   # 22 modules
│   │   │   └── application-resources/  # 13 modules
│   │   ├── bootstrap/dev/
│   │   └── packer/
│   └── azure/                 # Early Azure composition modules
│       └── modules/composition/  # 2 modules
├── load-test/                 # Python/Locust load testing
│   ├── locustfile.py
│   ├── script.py
│   ├── merchant_create.py
│   ├── requirements.txt
│   ├── setup.sh
│   └── dashboards.json
├── .github/workflows/         # CI workflows
│   ├── pre-commit.yml
│   ├── python-ci.yml
│   ├── security-scan.yml
│   ├── terraform-docs.yml
│   ├── terraform-validate.yml
│   └── terragrunt-validate-gcp.yml
├── justfile                   # Local development recipes
├── .paperclip-skills/         # Custom Paperclip agent skills (5 skills)
│   ├── terraform-review/
│   ├── security-audit/
│   ├── drift-detection/
│   ├── pr-review/
│   └── cost-analysis/
└── .claude/                   # Claude Code settings
    └── settings.local.json
```

## Tech Stack

| Category | Technology | Version / Notes |
|---|---|---|
| IaC | Terraform | >= 1.0 (AWS/GCP), >= 1.12.0 (OCI bootstrap), >= 1.5.0 (OCI/Azure modules) |
| Live layer | Terragrunt | Used for AWS live, GCP live and GCP catalog |
| Cloud Providers | AWS | Provider ~> 5.0 |
| | GCP | Provider ~> 5.x |
| | OCI | Provider ~> 9.0 |
| | Azure | Provider ~> 5.4 |
| Container Orchestration | EKS / GKE / OKE | Kubernetes >= 1.28 (AWS) |
| GitOps | ArgoCD | Helm-based |
| Service Mesh | Istio | Helm-based |
| Database | Aurora PostgreSQL / AlloyDB / OCI Database | Managed or EC2-based |
| Cache | ElastiCache Redis / Memorystore Valkey / OCI Cache Valkey | Managed |
| Wide-Column Store | Cassandra | EC2-based |
| CDN | CloudFront / Cloud CDN | With OAC, Functions |
| Observability | Grafana + Loki + Vector | Helm-based |
| Secrets | External Secrets Operator | AWS Secrets Manager / GCP Secret Manager |
| Ingress | Envoy Proxy | ALB/ASG or GCE LB |
| Egress | Squid Proxy | NLB/ASG or GCE LB |
| Load Testing | Python + Locust | pip-based |
| CI/CD | GitHub Actions | — |
| Local Helpers | just | Recipes in `justfile` |

## Development Commands

### Terraform / Terragrunt

```bash
# Format all Terraform files
terraform fmt -recursive terraform/

# Validate an AWS live component (requires terragrunt init first)
cd terraform/aws/live/dev/eu-central-1/<component>
terragrunt plan

# Validate a GCP catalog unit
cd terraform/gcp/catalog/units/<unit>
terragrunt hcl validate

# Check GCP catalog pins resolve to real tags
bash scripts/ci/check-gcp-pins.sh
```

### Local helpers (justfile)

```bash
just gen-docs        # regenerate module READMEs via terraform-docs
just check-docs      # check terraform-docs is installed
just clean-cache     # remove .terraform / .terragrunt-cache / lock files
just list-cache      # dry-run list of caches
```

### Python / Load Testing

```bash
cd load-test && python -m pytest
cd load-test && ruff check .
```

### CI (GitHub Actions)

The following workflows run on PRs:

1. `pre-commit.yml` — pre-commit hooks (if configured locally)
2. `python-ci.yml` — Python lint/tests for `load-test/`
3. `security-scan.yml` — Sensitive-data and security scanning
4. `terraform-docs.yml` — Auto-regenerate module READMEs
5. `terraform-validate.yml` — `terraform fmt`, `tflint`, `terraform validate`
6. `terragrunt-validate-gcp.yml` — `terragrunt hcl format`, sensitive scan, catalog pin checks

## Code Conventions

### Module Architecture

Terraform modules follow a strict layered architecture. **Never run Terraform directly in module directories** — they are libraries/templates consumed by live deployments.

1. **Base modules** (`modules/base/`) — Atomic AWS resource wrappers. Each module wraps a single AWS resource type. (AWS only today.)
2. **Composition modules** (`modules/composition/`) — Service orchestration combining base modules into deployable units.
3. **Application resources** (`modules/application-resources/`) — EKS/GKE/OKE workload modules deployed via ArgoCD/Helm.
4. **Live deployments** (`live/`) — Environment-specific Terragrunt configurations that instantiate modules.

### Catalog / Unit Pattern (GCP today, proposed for AWS)

- Each **unit** is a `terragrunt.hcl` that wraps exactly one module at a pinned git tag: `?ref=<cloud>-<module>-vX.Y.Z`.
- Units are environment-agnostic; environment values are injected by a Terragrunt Stack (`catalog/stacks/internal`) and rendered into a generated live tree.
- GCP uses `gcp-<module>-vX.Y.Z` and `gcp-apps-<module>-vX.Y.Z`. Going forward, AWS module tags should use `aws-<module>-vX.Y.Z` to avoid collisions with OCI/Azure tags.

### Terraform Standards

- Every variable must have a `description` field.
- Every output must have a `description` field.
- Use remote state backends (S3/DynamoDB for AWS, GCS for GCP, local then migrated for OCI) for all live components.
- Cross-component data sharing uses `terraform_remote_state` data sources or Terragrunt `dependency` blocks.
- Provider and Terraform versions must be pinned in `versions.tf`.
- Security groups default to deny; explicitly allow only needed traffic.
- All sensitive data is managed through External Secrets Operator backed by a secrets manager.
- S3 buckets must have versioning, encryption, and access logging enabled.
- Resources must follow organisational naming conventions and tagging standards.

### Deployment Order (AWS)

Components must be deployed in dependency order:

1. **Bootstrap** (one-time) — S3 + DynamoDB state backend
2. **vpc-network** — VPC, subnets, NAT, endpoints
3. **Core Services** (parallel) — database, elasticache, ecr, jump-host, cassandra, opensearch
4. **EKS** — Cluster + node groups
5. **EKS Kubernetes Resources** — RBAC, storage, autoscaler
6. **Apps Layer** — alb-controller → istio → external-secrets-operator → argocd → hyperswitch-app → grafana → loki → vector
7. **Proxy Layer** — envoy-proxy, squid-proxy
8. **CloudFront** — CDN distributions
9. **Security Rules** (DEPLOY LAST) — Cross-module security group rules

GCP follows a similar order; see `terraform/gcp/catalog/README.md` for unit dependencies.

## Security Considerations

This is a **payment processing platform** subject to PCI DSS compliance requirements.

### Critical Rules
- Never commit secrets, API keys, or credentials to the repository.
- All resources handling payment data must have encryption at rest and in transit.
- IAM policies must follow least privilege — flag any `*:*` or overly broad permissions.
- Security group changes are always high-priority — never open unnecessary access.
- Changes to production-facing resources (EKS, RDS, security groups) need extra review.
- Cardholder data environment must be isolated from general workloads.
- All publicly accessible resources must have WAF or CloudFront protection.
- Never disable security controls for convenience.

### PCI DSS Scope
- EKS clusters running payment services
- Aurora PostgreSQL databases storing transaction data
- ElastiCache Redis for session and caching
- Locker service (card vault) with dedicated EC2 + NLB
- Network segmentation between payment and non-payment workloads
- Logging and monitoring coverage for all payment-processing resources

## Related Repositories

| Repository | Description | Language |
|---|---|---|
| [juspay/hyperswitch](https://github.com/juspay/hyperswitch) | App server — core payment processing engine | Rust |
| [juspay/hyperswitch-web](https://github.com/juspay/hyperswitch-web) | Web client — payment form SDK | TypeScript |
| [juspay/hyperswitch-control-center](https://github.com/juspay/hyperswitch-control-center) | Dashboard — merchant admin panel | TypeScript |
| [juspay/hyperswitch-card-vault](https://github.com/juspay/hyperswitch-card-vault) | Card vault — secure card storage | Rust |

## Paperclip Integration

This repository is configured with a Paperclip company **"Hyperswitch Infrastructure"** running in `local_trusted` mode at `http://127.0.0.1:3100`.

### Organisation Structure
- CEO → Infra Lead → Terraform Engineer, Security Engineer, Code Reviewer
- CEO → Cost Analyst

### Custom Skills (`.paperclip-skills/`)

| Skill | Purpose |
|---|---|
| `terraform-review` | Reviews Terraform code for best practices, security, and compliance with Hyperswitch standards |
| `security-audit` | Performs security audit on infrastructure with PCI DSS compliance focus |
| `drift-detection` | Detects infrastructure drift by comparing Terraform state with actual AWS resources |
| `pr-review` | Reviews pull requests for infrastructure safety, security, and best practices |
| `cost-analysis` | Analyses AWS infrastructure costs and identifies optimisation opportunities |

### Scheduled Routines
| Routine | Schedule | Skill |
|---|---|---|
| Nightly drift detection | 2:00 AM UTC daily | `drift-detection` |
| Weekly security audit | Monday 3:00 AM UTC | `security-audit` |
| Monthly cost analysis | 1st of month 4:00 AM UTC | `cost-analysis` |

## Common Tasks

### Add a new AWS resource type
1. Create a new base module under `terraform/aws/modules/base/<resource>/`
2. Add `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
3. Ensure all variables and outputs have descriptions
4. Add a composition module if combining multiple base modules
5. Test by adding a live deployment config

### Add a new EKS application
1. Create a new application-resources module under `terraform/aws/modules/application-resources/<app>/`
2. Add a live deployment under `terraform/aws/live/dev/eu-central-1/apps/<app>/`
3. Configure ArgoCD to manage the deployment
4. Add security group rules in `security-rules/` if the app needs network access

### Add a new GCP catalog unit
1. Ensure the module is committed and tagged `gcp-<module>-vX.Y.Z` or `gcp-apps-<module>-vX.Y.Z`
2. Add a unit under `terraform/gcp/catalog/units/<path>/terragrunt.hcl`
3. Declare dependencies with `mock_outputs`
4. Run `bash scripts/ci/check-gcp-pins.sh` to verify the pin

### Modify existing infrastructure
1. Identify the affected component in the correct cloud's `live/` or `catalog/units/`
2. Run `terraform plan` or `terragrunt plan` to understand the impact
3. For destructive changes, ensure state migration is handled
4. Update `CHANGELOG.md` for significant changes
5. Deploy `security-rules/` last if network access is affected
