# Terraform Architecture Documentation

Production-ready Terraform infrastructure for Hyperswitch payment services with modular, multi-layer architecture.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              LIVE LAYER                                      │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐                         │
│  │   dev   │  │  integ  │  │   prod  │  │ sandbox │                         │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘                         │
│       │            │            │            │                               │
│       └────────────┴────────────┴────────────┘                               │
│                          │                                                   │
│                    Environment-specific                                       │
│                    configurations & values                                    │
└──────────────────────────┼──────────────────────────────────────────────────┘
                           │
┌──────────────────────────┼──────────────────────────────────────────────────┐
│                     MODULE LAYER                                              │
│  ┌───────────────────────┼───────────────────────┐                          │
│  │   APPLICATION RESOURCES                       │                          │
│  │  alb-controller, argocd, eks-iam,             │                          │
│  │  external-secrets, hyperswitch, istio         │                          │
│  └───────────────────────┬───────────────────────┘                          │
│  ┌───────────────────────┼───────────────────────┐                          │
│  │      COMPOSITION MODULES                      │                          │
│  │  vpc-network, eks, cloudfront, database,      │                          │
│  │  elasticache, envoy-proxy, squid-proxy, etc.  │                          │
│  └───────────────────────┬───────────────────────┘                          │
│  ┌───────────────────────┼───────────────────────┐                          │
│  │         BASE MODULES                          │                          │
│  │  vpc, subnet, security-group, asg, alb, nlb,  │                          │
│  │  iam-role, s3-bucket, target-group, etc.      │                          │
│  └───────────────────────┴───────────────────────┘                          │
│                                                                               │
│  ┌───────────────────────────────────────────────┐                          │
│  │         CLOUDFRONT RESOURCES                  │                          │
│  │  Shared CloudFront policies, functions, OAC   │                          │
│  └───────────────────────────────────────────────┘                          │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## Module Architecture

The infrastructure is built on a **four-layer module architecture** that separates concerns and enables reusability.

### Layer 1: Base Modules (`modules/base/`)

Atomic AWS resource wrappers - generic building blocks with no business logic. **Never run Terraform here** - these are libraries.

| Module | Purpose | Key Resources |
|--------|---------|---------------|
| `vpc/` | VPC creation with DNS, flow logs, IGW | `aws_vpc`, `aws_internet_gateway`, `aws_flow_log` |
| `subnet/` | Subnet creation with NAT, routing | `aws_subnet`, `aws_nat_gateway`, `aws_eip` |
| `security-group/` | Security group with rules | `aws_security_group` |
| `security-group-rules/` | Cross-module security group rules | `aws_security_group_rule` |
| `route-table/` | Route table management | `aws_route_table`, `aws_route` |
| `network-acl/` | Network ACL configuration | `aws_network_acl`, `aws_network_acl_rule` |
| `vpc-endpoint/` | VPC endpoints (Gateway/Interface) | `aws_vpc_endpoint` |
| `asg/` | Auto Scaling Group with launch template | `aws_autoscaling_group`, `aws_launch_template` |
| `launch-template/` | EC2 launch configuration | `aws_launch_template` |
| `alb/` | Application Load Balancer | `aws_lb` |
| `alb-listener/` | ALB listeners and rules | `aws_lb_listener`, `aws_lb_listener_rule` |
| `nlb/` | Network Load Balancer | `aws_lb` |
| `nlb-listener/` | NLB listeners | `aws_lb_listener` |
| `target-group/` | Load balancer target groups | `aws_lb_target_group` |
| `iam-role/` | IAM roles with policies | `aws_iam_role`, `aws_iam_role_policy` |
| `s3-bucket/` | S3 bucket with encryption, lifecycle | `aws_s3_bucket`, versioning, policies |
| `dynamodb-table/` | DynamoDB tables | `aws_dynamodb_table` |
| `lambda/` | Lambda functions | `aws_lambda_function` |
| `api-gateway/` | API Gateway REST APIs | `aws_api_gateway_rest_api` |

### Layer 2: Composition Modules (`modules/composition/`)

Service orchestration combining base modules into deployable units. **Never run Terraform here** - these are templates.

| Module | Purpose | Components |
|--------|---------|------------|
| `vpc-network/` | Complete VPC with multi-tier subnets | VPC + Subnets + NAT + Route Tables + VPC Endpoints + NACLs |
| `eks/` | EKS cluster with node groups | EKS Cluster + Node Groups + IAM Roles + Addons + IRSA |
| `eks-kubernetes-resources/` | Kubernetes resources for EKS | RBAC + Storage Classes + Cluster Autoscaler + Helm Deployments |
| `cloudfront/` | CloudFront CDN distributions | Distributions + OAC + Functions + Policies |
| `database/` | RDS Aurora PostgreSQL | Aurora Cluster + Instances + Parameter Groups + Backups |
| `elasticache/` | ElastiCache Redis | Replication Group + Subnet Group + Security Group |
| `envoy-proxy/` | Ingress proxy layer | ALB + ASG + S3 Config + Security Groups |
| `squid-proxy/` | Outbound HTTP/HTTPS proxy | NLB + ASG + S3 Config/Logs + Security Groups |
| `locker/` | Card vault service | EC2 + NLB + Security Groups + IAM |
| `jump-host/` | Bastion host for SSH access | EC2 + Security Groups + IAM |
| `cassandra/` | Apache Cassandra cluster | EC2 + ASG + Security Groups |
| `load-balancer/` | Shared load balancer infrastructure | ALB/NLB + Target Groups + Listeners |
| `security-rules/` | Cross-module security group rules | Security Group Rules |
| `ecr/` | Elastic Container Registry | ECR Repositories + Lifecycle Policies |
| `terraform-backend/` | Terraform state infrastructure | S3 Bucket + DynamoDB Table |

### Layer 3: Application Resources (`modules/application-resources/`)

Application-specific resources that run on top of EKS. May require Kubernetes cluster to exist.

| Module | Purpose |
|--------|---------|
| `alb-controller/` | AWS Load Balancer Controller for Kubernetes |
| `argocd/` | ArgoCD GitOps deployment |
| `eks-iam/` | EKS IAM roles for service accounts (IRSA) |
| `external-secrets-operator/` | External Secrets Operator deployment |
| `hyperswitch/` | Hyperswitch application resources (S3, KMS, IAM) |
| `istio/` | Istio service mesh deployment |
| `shared-policy/` | Shared IAM policies across services |

### Layer 4: CloudFront Resources (`modules/cloudfront-resources/`)

Shared CloudFront infrastructure - policies, functions, and origin access controls.

| Resource Type | Purpose |
|---------------|---------|
| `cloudfront_functions` | Edge functions for request/response manipulation |
| `response_headers_policies` | Security headers, CORS configuration |
| `cache_policies` | Caching behavior policies |
| `origin_request_policies` | Origin request forwarding rules |

---

## Live Layer Architecture

Environment-specific deployments in `live/` directory. **This is where Terraform commands run.**

### Environments

| Environment | State Backend | Encryption | Use Case |
|-------------|---------------|------------|----------|
| `dev/` | S3 or local | AES256 | Development, testing, reference |
| `integ/` | S3 + DynamoDB | AES256 | Integration testing, UAT |
| `prod/` | S3 + DynamoDB | KMS | Production workloads |
| `sandbox/` | S3 + DynamoDB | AES256 | Experimentation, POC |

### Dev Environment Components (`live/dev/eu-central-1/`)

#### Infrastructure Components

| Component | Module | Purpose | Dependencies |
|-----------|--------|---------|--------------|
| `vpc-network/` | `composition/vpc-network` | VPC, subnets, NAT, endpoints | None (foundation) |
| `eks/` | `composition/eks` | Kubernetes cluster | `vpc-network` |
| `eks-kubernetes-resources/` | `composition/eks-kubernetes-resources` | K8s resources, autoscaler | `eks` |
| `cloudfront/` | `composition/cloudfront` | CDN distributions | `envoy-proxy` (origin) |
| `database/` | `composition/database` | Aurora PostgreSQL | `vpc-network` |
| `elasticache/` | `composition/elasticache` | Redis cache | `vpc-network` |
| `ecr/` | `composition/ecr` | Container registry | None |

#### Proxy Components

| Component | Module | Purpose | Dependencies |
|-----------|--------|---------|--------------|
| `envoy-proxy/` | `composition/envoy-proxy` | Ingress proxy | `vpc-network` |
| `squid-proxy/` | `composition/squid-proxy` | Outbound proxy | `vpc-network` |

#### Security Components

| Component | Module | Purpose | Dependencies |
|-----------|--------|---------|--------------|
| `security-rules/` | `composition/security-rules` | Cross-module SG rules | All infrastructure |
| `jump-host/` | `composition/jump-host` | Bastion access | `vpc-network` |

#### Application Components

| Component | Module | Purpose | Dependencies |
|-----------|--------|---------|--------------|
| `locker/` | `composition/locker` | Card vault service | `vpc-network`, `database` |
| `cassandra/` | `composition/cassandra` | NoSQL database | `vpc-network` |

#### Apps (Kubernetes Workloads)

| Component | Purpose | Dependencies |
|-----------|---------|--------------|
| `alb-controller/` | AWS LB Controller | `eks`, `eks-kubernetes-resources` |
| `argocd/` | GitOps deployment | `eks` |
| `istio/` | Service mesh | `eks` |
| `external-secrets-operator/` | Secrets management | `eks` |
| `eso-hyperswitch/` | Hyperswitch secrets | `external-secrets-operator` |
| `hyperswitch-app/` | Main application | `eks`, `database`, `elasticache` |
| `grafana/` | Monitoring dashboards | `eks` |
| `loki/` | Log aggregation | `eks` |
| `vector/` | Metrics collection | `eks` |
| `shared-policies/` | Shared IAM policies | `eks` |

---

## Dependency Graph

### Deployment Order

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  PHASE 1: FOUNDATION                                                         │
│  ┌─────────────┐                                                             │
│  │ vpc-network │  ← Deploy first (no dependencies)                           │
│  └──────┬──────┘                                                             │
│         │                                                                    │
└─────────┼────────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  PHASE 2: CORE SERVICES                                                      │
│                                                                              │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐                  │
│  │ database │   │elasticache│   │   ecr    │   │jump-host │                  │
│  └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘                  │
│       │              │              │              │                         │
│       └──────────────┴──────────────┴──────────────┘                         │
│                              │                                               │
│                     All depend on vpc-network                                │
└──────────────────────────────┼──────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  PHASE 3: KUBERNETES CLUSTER                                                 │
│                                                                              │
│  ┌──────────────────────────────┐                                            │
│  │            eks               │  ← Depends on vpc-network                  │
│  └──────────────┬───────────────┘                                            │
│                 │                                                            │
│                 ▼                                                            │
│  ┌──────────────────────────────┐                                            │
│  │   eks-kubernetes-resources   │  ← Depends on eks                          │
│  └──────────────┬───────────────┘                                            │
│                 │                                                            │
│                 ▼                                                            │
│  ┌────────────────────────────────────────────────────────────────────┐      │
│  │                        APPS LAYER                                   │      │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │      │
│  │  │alb-ctlr  │ │  argocd  │ │  istio   │ │   eso    │ │ grafana  │  │      │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘  │      │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐               │      │
│  │  │  loki    │ │  vector  │ │ hypersw- │ │shared-   │               │      │
│  │  │          │ │          │ │   itch   │ │ policies │               │      │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘               │      │
│  └────────────────────────────────────────────────────────────────────┘      │
└───────────────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  PHASE 4: PROXY & INGRESS                                                    │
│                                                                              │
│  ┌──────────────┐        ┌──────────────┐                                    │
│  │ envoy-proxy  │        │ squid-proxy  │                                    │
│  └──────┬───────┘        └──────┬───────┘                                    │
│         │                       │                                            │
│         └───────────────────────┘                                            │
│                     │                                                        │
│            Depend on vpc-network                                             │
│                     │                                                        │
│                     ▼                                                        │
│  ┌──────────────────────────────┐                                            │
│  │         cloudfront           │  ← Depends on envoy-proxy (origin)         │
│  └──────────────────────────────┘                                            │
└───────────────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  PHASE 5: SECURITY RULES (LAST)                                              │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                       security-rules                                 │    │
│  │   Configures cross-module SG rules for:                             │    │
│  │   - locker ↔ jump-host                                              │    │
│  │   - envoy ↔ jump-host, EKS                                          │    │
│  │   - squid ↔ EKS                                                     │    │
│  │   - cassandra ↔ jump-host                                           │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ⚠️  Must be deployed LAST after all infrastructure components             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Component Dependency Matrix

| Component | vpc-network | eks | database | elasticache | envoy | cloudfront | security-rules |
|-----------|:-----------:|:---:|:--------:|:-----------:|:-----:|:----------:|:--------------:|
| vpc-network | - | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| eks | ✅ | - | ❌ | ❌ | ❌ | ❌ | ❌ |
| database | ✅ | ❌ | - | ❌ | ❌ | ❌ | ❌ |
| elasticache | ✅ | ❌ | ❌ | - | ❌ | ❌ | ❌ |
| ecr | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| jump-host | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| locker | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| cassandra | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| envoy-proxy | ✅ | ❌ | ❌ | ❌ | - | ❌ | ❌ |
| squid-proxy | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| cloudfront | ✅ | ✅ | ❌ | ❌ | ✅ | - | ❌ |
| eks-k8s-resources | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| apps/* | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| security-rules | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | - |

---

## Network Architecture

### VPC Subnet Tiers

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              VPC (10.0.0.0/16)                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ EXTERNAL-INCOMING (Public) - ALB, NAT Gateway                       │    │
│  │ 10.0.64.0/24, 10.0.65.0/24, 10.0.66.0/24                           │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ MANAGEMENT (Public) - Bastion/Jump Host                             │    │
│  │ 10.0.67.0/24, 10.0.68.0/24, 10.0.69.0/24                           │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ EKS-WORKERS (Private with NAT) - Kubernetes worker nodes            │    │
│  │ 10.0.32.0/21, 10.0.40.0/21, 10.0.48.0/21 (2,048 IPs each)         │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ EKS-CONTROL-PLANE (Private Isolated) - EKS control plane            │    │
│  │ 10.0.70.0/24, 10.0.71.0/24, 10.0.72.0/24                           │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ DATABASE (Private Isolated) - RDS, Aurora                           │    │
│  │ 10.0.73.0/24, 10.0.74.0/24, 10.0.75.0/24                           │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ LOCKER-DATABASE (Private Isolated, PCI-DSS)                         │    │
│  │ 10.0.76.0/24, 10.0.77.0/24, 10.0.78.0/24                           │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ LOCKER-SERVER (Private Isolated, PCI-DSS)                           │    │
│  │ 10.0.79.0/24, 10.0.80.0/24, 10.0.81.0/24                           │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ ELASTICACHE (Private Isolated) - Redis                              │    │
│  │ 10.0.82.0/24, 10.0.83.0/24, 10.0.84.0/24                           │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ INCOMING-ENVOY (Private with NAT) - Envoy proxy instances           │    │
│  │ 10.0.88.0/24, 10.0.89.0/24, 10.0.90.0/24                           │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ OUTGOING-PROXY (Private with NAT) - Squid proxy instances           │    │
│  │ 10.0.91.0/24, 10.0.92.0/24, 10.0.93.0/24                           │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ UTILS, LAMBDA, DATA-STACK (Private Isolated/NAT)                    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Traffic Flows

#### Ingress Flow (CloudFront → EKS)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  CloudFront │────▶│ External ALB│────▶│    Envoy    │────▶│  Internal   │
│    (CDN)    │     │   (Public)  │     │   Proxy     │     │     ALB     │
└─────────────┘     └─────────────┘     └─────────────┘     └──────┬──────┘
                                                                   │
                                                                   ▼
                                                            ┌─────────────┐
                                                            │     EKS     │
                                                            │   Cluster   │
                                                            └─────────────┘
```

#### Egress Flow (EKS → Internet via Squid)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ EKS Pods    │────▶│     NLB     │────▶│    Squid    │────▶│  Internet   │
│             │     │  (TCP:80)   │     │   Proxy     │     │(whitelisted)│
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

---

## Security Architecture

### Network Security

- **No Public IPs**: All instances in private subnets (except bastion with Elastic IP)
- **Security Groups**: Least-privilege rules, no 0.0.0.0/0 ingress
- **NACLs**: Additional layer of subnet-level filtering
- **VPC Endpoints**: S3, DynamoDB, ECR, SSM, Secrets Manager via endpoints (no NAT)

### IAM Security

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           IAM Role Architecture                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  EKS Cluster Role                                                            │
│  ├── AmazonEKSClusterPolicy                                                  │
│  ├── AmazonEKSVPCResourceController                                          │
│  └── Custom policies for KMS, logging                                        │
│                                                                              │
│  EKS Node Group Role                                                         │
│  ├── AmazonEKSWorkerNodePolicy                                               │
│  ├── AmazonEKS_CNI_Policy                                                    │
│  ├── AmazonEC2ContainerRegistryReadOnly                                      │
│  └── AmazonSSMManagedInstanceCore                                            │
│                                                                              │
│  IRSA (IAM Roles for Service Accounts)                                       │
│  ├── ebs-csi-controller-sa → EBS CSI Driver                                  │
│  ├── cluster-autoscaler → Cluster Autoscaler                                 │
│  └── Custom service accounts → Application-specific                          │
│                                                                              │
│  Cross-Account Role (Management Cluster Access)                              │
│  └── ArgoCD, Atlantis from management cluster                                │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Data Encryption

| Resource | Encryption | Key Management |
|----------|------------|----------------|
| S3 Buckets | AES256 / KMS | AWS-managed or Customer-managed |
| EBS Volumes | AES256 | KMS |
| RDS/Aurora | AES256 | KMS |
| ElastiCache | At-rest & In-transit | KMS + Auth Token |
| Terraform State | AES256 / KMS | S3 encryption |
| Secrets | KMS | AWS Secrets Manager |

---

## State Management

### Backend Configuration

Each environment has isolated state files stored in S3 with DynamoDB locking:

```
S3 Bucket: hyperswitch-{env}-terraform-state
├── dev/eu-central-1/
│   ├── vpc-network/terraform.tfstate
│   ├── eks/terraform.tfstate
│   ├── database/terraform.tfstate
│   ├── cloudfront/terraform.tfstate
│   ├── envoy-proxy/terraform.tfstate
│   ├── squid-proxy/terraform.tfstate
│   ├── security-rules/terraform.tfstate
│   └── ... (other components)
└── bootstrap/

DynamoDB Table: hyperswitch-{env}-terraform-state-lock
```

### State Isolation Benefits

- **Blast Radius Control**: Each component has isolated state
- **Parallel Development**: Teams can work on different components
- **Selective Rollback**: Roll back individual components
- **Environment Isolation**: dev/integ/prod completely separate

### Bootstrap Process

```bash
# 1. Bootstrap state infrastructure first
cd bootstrap/dev
terraform init
terraform apply

# 2. Configure backend for all components
# Each component has backend.tf pointing to the bootstrap bucket
```

---

## Monitoring & Observability

### Metrics

| Component | Metrics Source |
|-----------|----------------|
| EKS Cluster | CloudWatch Container Insights |
| ASG (Envoy/Squid) | CloudWatch EC2 metrics |
| ALB/NLB | CloudWatch ELB metrics |
| RDS/Aurora | CloudWatch RDS metrics |
| ElastiCache | CloudWatch ElastiCache metrics |

### Logging

| Component | Log Destination |
|-----------|-----------------|
| EKS Pods | CloudWatch Logs / Loki |
| Envoy/Squid | S3 + CloudWatch Logs |
| System Logs | CloudWatch Logs |
| Audit Logs | CloudTrail |

---

## Cost Optimization

### Development Environment

| Resource | Configuration | Est. Monthly Cost |
|----------|---------------|-------------------|
| NAT Gateway | 1x (shared) | ~$35 |
| EKS Cluster | 1x (minimum nodes) | ~$75 |
| RDS Aurora | db.t4g.medium | ~$50 |
| ElastiCache | cache.t4g.micro | ~$15 |
| **Total** | | ~$175-250/month |

### Production Environment

| Resource | Configuration | Est. Monthly Cost |
|----------|---------------|-------------------|
| NAT Gateway | 3x (per AZ) | ~$105 |
| EKS Cluster | Multi-node HA | ~$300+ |
| RDS Aurora | db.r5.large Multi-AZ | ~$400+ |
| ElastiCache | Multi-AZ | ~$200+ |
| CloudFront | By usage | Variable |
| **Total** | | ~$1,000+/month |

---

## Architecture Benefits

| Benefit | How It's Achieved |
|---------|-------------------|
| **Modularity** | Four-layer architecture with clear separation |
| **Reusability** | Base modules used across all compositions |
| **Security** | Defense in depth: VPC, SG, NACL, IAM, encryption |
| **Scalability** | ASG-based components, EKS for workloads |
| **Reliability** | Multi-AZ deployments, automatic failover |
| **Cost Control** | Environment-specific sizing, spot instances |
| **Maintainability** | Isolated state, independent deployments |
| **GitOps Ready** | ArgoCD integration, infrastructure as code |
