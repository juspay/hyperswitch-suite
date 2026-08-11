# OCI Composition Modules

OCI (Oracle Cloud Infrastructure) equivalents of `terraform/aws/modules/composition/*`. Scope: **composition modules only** (`terraform/aws/modules/application-resources` is not covered here — those modules are mostly cloud-agnostic Helm/Kubernetes-provider deployments; only their cloud-specific pieces, e.g. `eks-kubernetes-resources`, are ported).

## Conventions

- **No `base` module layer.** The AWS tree has `modules/base/*` (thin wrappers the composition modules assemble). Per the design decision for this port, OCI composition modules either call an **official** module straight from the Terraform Registry, or write `oci` provider resources directly inline — there is no `terraform/oci/modules/base`.
- **Registry sourcing rule.** Only modules published under the Terraform Registry `oracle-terraform-modules` namespace **with `verified: true`** are used as registry module dependencies (this is Oracle's own GitHub org, and the registry's `verified` flag is the closest signal to "official" for OCI, since Oracle does not publish under a separate `oracle` provider-only namespace for modules). Where no verified module exists for a resource, we write plain resources against the official `oracle/oci` provider — still 100% sourced from the Terraform Registry, just not wrapped in a module.
- **Modules used:**
  - `oracle-terraform-modules/oke/oci` (v5.x, verified) — OKE cluster (AWS `eks` composition module)
  - `oracle-terraform-modules/compute-instance/oci` (v2.x, verified) — self-managed compute nodes (AWS EC2-based composition modules: `cassandra`, `clickhouse`, `kafka`, `locker`, `jump-host`)
  - `oracle-terraform-modules/iam/oci` (v2.x, verified) — used where convenient for dynamic-group/policy pairs
  - Everything else (VCN/subnets, load balancers, PostgreSQL, Redis, OpenSearch, Object/File/Container Storage, DNS, Certificates, Notifications, Monitoring/Logging, Instance Pools) is plain `oci_*` provider resources, because no verified registry module exists for these.

## AWS → OCI service mapping

| AWS composition module | AWS service(s) | OCI composition module | OCI service(s) | Notes |
|---|---|---|---|---|
| `vpc-network` | VPC, subnets, NAT/IGW, route tables | `vpc-network` | VCN, regional subnets, NAT/Internet/Service Gateway | OCI subnets are regional (not AZ-pinned), so the AWS per-AZ subnet fan-out collapses to one subnet per tier |
| `eks` | EKS | `eks` | OKE (Container Engine for Kubernetes) | via `oracle-terraform-modules/oke/oci` |
| `eks-kubernetes-resources` | K8s/Helm resources on EKS | `eks-kubernetes-resources` | K8s/Helm resources on OKE | Kubernetes/Helm providers are cloud-agnostic; only CSI provisioner, IRSA→Workload Identity, ECR→OCIR, `--cloud-provider` flag change |
| `database` (Aurora PostgreSQL) | RDS/Aurora | `database` | OCI Database with PostgreSQL | `oci_psql_db_system` |
| `elasticache` (Redis) | ElastiCache | `elasticache` | OCI Cache with Redis | `oci_redis_redis_cluster` |
| `opensearch` | Amazon OpenSearch Service | `opensearch` | OCI Search with OpenSearch | `oci_opensearch_opensearch_cluster` |
| `cassandra` | Self-managed EC2 | `cassandra` | Self-managed Compute | NSGs, block volumes, dynamic group/policy instead of IAM role/instance profile |
| `clickhouse` | Self-managed EC2 + ALB | `clickhouse` | Self-managed Compute + LB | Same pattern |
| `kafka` | Self-managed EC2 | `kafka` | Self-managed Compute | Same pattern |
| `locker` | Self-managed EC2 + ALB + RDS | `locker` | Self-managed Compute + LB + `database` | Same pattern |
| `load-balancer` | ALB + Route53 | `load-balancer` | OCI Load Balancer + DNS | |
| `acm` | ACM | `acm` | OCI Certificates Service | `oci_certificates_management_certificate` |
| `route53` | Route53 | `route53` | OCI DNS | `oci_dns_zone` / `oci_dns_rrset` |
| `cloudfront` | CloudFront | `cloudfront` | **Gap — see module README** | OCI has no general-purpose CDN PaaS with a Terraform resource; module wires OCI WAF in front of the LB and documents the gap |
| `cloudwatch` | CloudWatch | `cloudwatch` | OCI Monitoring + Logging | `oci_monitoring_alarm`, `oci_logging_log_group`/`oci_logging_log` |
| `ecr` | ECR | `ecr` | OCIR (Container Registry) | `oci_artifacts_container_repository` |
| `efs` | EFS | `efs` | OCI File Storage (FSS) | `oci_file_storage_file_system` |
| `security-rules` | Cross-module SG rules | `security-rules` | Cross-module NSG rules | `oci_core_network_security_group_security_rule` |
| `jump-host` | EC2 bastion + SSM | `jump-host` | Compute bastion | OCI Bastion service (session-based, no persistent host) is the more "native" analog and is noted as an alternative in the module README, but a persistent compute instance is kept to match the AWS module's shape |
| `squid-proxy` | ASG + launch template + NLB | `squid-proxy` | Instance Pool + Instance Configuration + NLB | `oci_core_instance_pool`/`oci_core_instance_configuration` are OCI's ASG/launch-template equivalents |
| `envoy-proxy` | ASG + launch template + ALB | `envoy-proxy` | Instance Pool + Instance Configuration + LB | Same pattern |
| `sns` | SNS | `sns` | OCI Notifications | `oci_ons_notification_topic`/`oci_ons_subscription` |
| `terraform-backend` | S3 + DynamoDB | `terraform-backend` | Object Storage (+ optional NoSQL lock table) | Terraform's S3-compatible backend can target OCI Object Storage's S3 Compatibility API directly; Terraform ≥1.10 does native conditional-write locking against it, so a lock table is optional |

## Known gaps

- **CloudFront / CDN.** No direct OCI equivalent exists. See `cloudfront/README.md`.
- **Aurora-specific features** (global database, Serverless v2 autoscaling, S3 import/export) have no OCI PostgreSQL equivalent and are omitted.
- **DynamoDB-style state locking** has no managed equivalent; use the S3-compatible backend's native locking, or the optional NoSQL table in `terraform-backend`.
