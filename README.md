# Hyperswitch Suite — Infrastructure as Code

This repository contains the Terraform and Terragrunt modules used to deploy the [Hyperswitch](https://github.com/juspay/hyperswitch) payment switch on AWS, GCP, OCI and Azure. It is the infrastructure counterpart of the application repos; if you are looking for the payment server itself, see [`juspay/hyperswitch`](https://github.com/juspay/hyperswitch).

## What this repo provides

- **Multi-cloud Terraform modules** organised in a layered architecture: base resources, service compositions, and EKS/GKE/OKE application resources.
- **Terragrunt live layers** for real, deployed environments, plus a tag-pinned **catalog/unit** pattern for reproducible module consumption.
- **Bootstrap, networking, compute, data stores, proxies, CDN, observability and GitOps** components needed for a PCI-aligned deployment.
- **CI workflows** for formatting, linting, validation, security scanning and catalog pin checks.
- **Load-testing fixtures** and supporting tooling.

## Cloud maturity

| Cloud | Status | Live layer | Catalog/Units | Modules | Notes |
|---|---|---|---|---|---|
| **AWS** | Production-capable | `terraform/aws/live/dev/eu-central-1/` (Terragrunt) | Proposed in [PR #302](https://github.com/juspay/hyperswitch-suite/pull/302) | Base + composition + application-resources + cloudfront-resources | Full bootstrap (`dev/integ/prod/sandbox`) and deployment guide |
| **GCP** | Dev live + catalog migration | `terraform/gcp/live/dev/asia-south1/` (Terragrunt) | `terraform/gcp/catalog/units/` (19 pinned units) | Composition + application-resources + packer | Catalog is the target pattern; stack/generated-live layer is in progress |
| **OCI** | Modules + bootstrap only | None in this repo | None | 22 composition + 13 application-resources + packer | Live layer planned in the `hyperswitch-infra` companion repo |
| **Azure** | Early modules only | None | None | 2 composition modules (`vpc-network`, `storage-account-backend`) | Bootstrap and live layer planned in `hyperswitch-infra` |

> **Why the split?** AWS and GCP live layers live here because they are actively deployed. OCI and Azure modules are staged here but their live/catalog layers are being built in a separate `hyperswitch-infra` repo that consumes these modules by tag.

## Repository layout

```
hyperswitch-suite/
├── terraform/
│   ├── aws/                    # Full AWS deployment suite
│   │   ├── modules/
│   │   │   ├── base/           # Atomic AWS resource wrappers
│   │   │   ├── composition/    # Service orchestration modules
│   │   │   ├── application-resources/  # EKS workload modules
│   │   │   └── cloudfront-resources/   # Shared CloudFront assets
│   │   ├── live/               # Terragrunt live environments
│   │   │   └── dev/eu-central-1/
│   │   └── bootstrap/          # S3 + DynamoDB state backend
│   ├── gcp/                    # GCP modules, live dev, and catalog units
│   │   ├── modules/
│   │   ├── catalog/units/      # Tag-pinned Terragrunt units
│   │   ├── live/dev/asia-south1/
│   │   └── packer/
│   ├── oci/                    # OCI modules + bootstrap (live elsewhere)
│   │   ├── modules/
│   │   ├── bootstrap/dev/
│   │   └── packer/
│   └── azure/                  # Early Azure composition modules
│       └── modules/composition/
├── load-test/                  # Python/Locust load tests
├── .github/workflows/          # CI: terraform-validate, terragrunt-validate-gcp, security-scan, etc.
├── justfile                    # Local helpers (docs, cache cleanup)
├── AGENTS.md                   # In-depth context for AI agents / contributors
├── terraform/aws/ARCHITECTURE.md   # AWS architecture and module deep dive
└── terraform/aws/README.md     # AWS deployment guide
```

## Architecture

Modules follow a strict layered design. **Never run Terraform directly inside module directories** — they are libraries consumed by the live layers.

1. **Base modules** — atomic cloud resources (VPC, subnet, IAM role, S3 bucket, etc.).
2. **Composition modules** — services built from base modules (VPC network, EKS, Aurora, ElastiCache, Envoy/Squid proxies, locker, etc.).
3. **Application resources** — Kubernetes workloads and supporting resources (ArgoCD, Istio, External Secrets Operator, Hyperswitch app resources, Grafana, Loki, Vector).
4. **Live layer** — environment-specific Terragrunt configurations that instantiate the modules above and wire remote state together.

See [`terraform/aws/ARCHITECTURE.md`](terraform/aws/ARCHITECTURE.md) for the full AWS architecture, dependency graph, and deployment order.

## Key documentation

| Document | Purpose |
|---|---|
| [`AGENTS.md`](./AGENTS.md) | Repo conventions, security rules, deployment order, common tasks |
| [`terraform/aws/ARCHITECTURE.md`](terraform/aws/ARCHITECTURE.md) | AWS module architecture and dependency graph |
| [`terraform/aws/README.md`](terraform/aws/README.md) | AWS step-by-step deployment guide |
| [`terraform/gcp/catalog/README.md`](terraform/gcp/catalog/README.md) | GCP catalog unit skeleton, tag naming and CI |
| [`CHANGELOG.md`](./CHANGELOG.md) | Suite release notes and upstream app compatibility |

## Development commands

```bash
# Format all Terraform files
terraform fmt -recursive terraform/

# Validate AWS live components (run inside the component dir)
cd terraform/aws/live/dev/eu-central-1/<component>
terragrunt plan

# Validate GCP catalog pins and formatting
just check-docs
bash scripts/ci/check-gcp-pins.sh
terragrunt hcl format --check --diff

# Run Python load-test checks
cd load-test && ruff check .
```

See [`justfile`](./justfile) for cache cleanup, docs generation and other helpers.

## Tagging and releases

- **Suite releases** are tagged `vX.Y` (e.g. `v1.21`). Each suite release documents infrastructure changes and links to the upstream [`juspay/hyperswitch`](https://github.com/juspay/hyperswitch) app release it was validated against.
- **Module tags** are cloud-prefixed where the catalog pattern is active:
  - GCP: `gcp-<module>-vX.Y.Z` and `gcp-apps-<module>-vX.Y.Z`
  - AWS: historically unprefixed (`<module>-vX.Y.Z`); new tags should follow the `aws-<module>-vX.Y.Z` convention to avoid collisions as OCI/Azure modules are tagged.
- See [`CHANGELOG.md`](./CHANGELOG.md) and [`terraform/gcp/catalog/README.md`](terraform/gcp/catalog/README.md) for details.

## Security

This is a payment-platform infrastructure repository. All changes that touch security groups, IAM, state backends, publicly exposed endpoints or cardholder-data-adjacent resources (EKS, RDS, ElastiCache, Locker) need extra review. See the *Security Considerations* section in [`AGENTS.md`](./AGENTS.md).

## Related repositories

| Repository | Description |
|---|---|
| [`juspay/hyperswitch`](https://github.com/juspay/hyperswitch) | App server — core payment processing engine |
| [`juspay/hyperswitch-web`](https://github.com/juspay/hyperswitch-web) | Web client / payment form SDK |
| [`juspay/hyperswitch-control-center`](https://github.com/juspay/hyperswitch-control-center) | Merchant admin dashboard |
| [`juspay/hyperswitch-card-vault`](https://github.com/juspay/hyperswitch-card-vault) | Card vault — secure card storage |

## License

This product is licensed under the [Apache 2.0 License](LICENSE).
