# Hyperswitch Terraform Infrastructure

Modular Terraform infrastructure for Hyperswitch payment services - a complete AWS deployment with VPC, EKS, databases, proxies, and CDN.

## Quick Links

- [Architecture Documentation](./ARCHITECTURE.md) - Detailed architecture and module documentation
- [Bootstrap README](./bootstrap/README.md) - State backend setup
- [Deployment Guide](#deployment-guide) - Step-by-step deployment instructions

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           LIVE LAYER                                     │
│         Environment-specific configurations (dev/integ/prod/sandbox)    │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
┌──────────────────────────────────────────────────────────────────────────┐
│                          MODULE LAYER                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐          │
│  │ Application     │  │ Composition     │  │ Base Modules    │          │
│  │ Resources       │  │ Modules         │  │ (Atomic AWS     │          │
│  │ (EKS apps)      │  │ (Services)      │  │  resources)     │          │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘          │
│  ┌──────────────────────────────────────────────────────────┐           │
│  │ CloudFront Resources (Shared policies, functions, OAC)   │           │
│  └──────────────────────────────────────────────────────────┘           │
└──────────────────────────────────────────────────────────────────────────┘
```

## Module Layers

### Base Modules (`modules/base/`)
Atomic AWS resource wrappers - **never run Terraform here** (libraries only).

- `vpc/`, `subnet/`, `route-table/`, `network-acl/`, `vpc-endpoint/`
- `security-group/`, `security-group-rules/`
- `asg/`, `launch-template/`
- `alb/`, `alb-listener/`, `nlb/`, `nlb-listener/`, `target-group/`
- `iam-role/`, `s3-bucket/`, `dynamodb-table/`
- `lambda/`, `api-gateway/`

### Composition Modules (`modules/composition/`)
Service orchestration combining base modules - **never run Terraform here** (templates only).

| Module | Purpose |
|--------|---------|
| `vpc-network` | Complete VPC with multi-tier subnets, NAT, endpoints |
| `eks` | EKS cluster with managed node groups |
| `eks-kubernetes-resources` | K8s resources, cluster autoscaler, Helm deployments |
| `cloudfront` | CDN distributions with OAC, functions, policies |
| `database` | RDS Aurora PostgreSQL cluster |
| `elasticache` | ElastiCache Redis replication group |
| `envoy-proxy` | Ingress proxy with ALB + ASG |
| `squid-proxy` | Outbound HTTP/HTTPS proxy with NLB + ASG |
| `locker` | Card vault service with EC2 + NLB |
| `jump-host` | Bastion host for SSH access |
| `security-rules` | Cross-module security group rules |

### Application Resources (`modules/application-resources/`)
EKS application-level resources.

- `alb-controller` - AWS Load Balancer Controller
- `argocd` - GitOps continuous deployment
- `istio` - Service mesh
- `external-secrets-operator` - Secrets management
- `hyperswitch` - Application-specific resources
- `eks-iam` - IRSA configurations
- `shared-policy` - Shared IAM policies

---

## Deployment Guide

### Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- kubectl (for EKS deployments)
- Helm 3.x (for Kubernetes deployments)

### Deployment Order

Components must be deployed in dependency order. Use the dependency graph below:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: FOUNDATION                                                          │
│                                                                              │
│   ┌─────────────────┐                                                        │
│   │  BOOTSTRAP      │  ← Create state backend (S3 + DynamoDB)               │
│   │  (one-time)     │                                                        │
│   └────────┬────────┘                                                        │
│            │                                                                 │
│            ▼                                                                 │
│   ┌─────────────────┐                                                        │
│   │  vpc-network    │  ← VPC, subnets, NAT, endpoints                       │
│   └────────┬────────┘                                                        │
│            │                                                                 │
└────────────┼────────────────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: CORE SERVICES (parallel after vpc-network)                          │
│                                                                              │
│   ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐               │
│   │ database  │  │elasticache│  │    ecr    │  │ jump-host │               │
│   └─────┬─────┘  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘               │
│         │              │              │              │                      │
└─────────┴──────────────┴──────────────┴──────────────┴──────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: KUBERNETES CLUSTER                                                  │
│                                                                              │
│   ┌─────────────────┐                                                        │
│   │      eks        │  ← EKS cluster + node groups                          │
│   └────────┬────────┘                                                        │
│            │                                                                 │
│            ▼                                                                 │
│   ┌─────────────────┐                                                        │
│   │ eks-kubernetes- │  ← RBAC, storage, autoscaler                          │
│   │    resources    │                                                        │
│   └────────┬────────┘                                                        │
│            │                                                                 │
│            ▼                                                                 │
│   ┌───────────────────────────────────────────────────────────────────┐     │
│   │                    APPS LAYER (EKS workloads)                      │     │
│   │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐     │     │
│   │  │alb-ctlr │ │ argocd  │ │  istio  │ │   eso   │ │ grafana │     │     │
│   │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘     │     │
│   │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐                 │     │
│   │  │  loki   │ │ vector  │ │hyper-sw │ │ shared- │                 │     │
│   │  │         │ │         │ │   itch  │ │ policies│                 │     │
│   │  └─────────┘ └─────────┘ └─────────┘ └─────────┘                 │     │
│   └───────────────────────────────────────────────────────────────────┘     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: PROXY & INGRESS                                                     │
│                                                                              │
│   ┌─────────────────┐        ┌─────────────────┐                            │
│   │  envoy-proxy    │        │  squid-proxy    │                            │
│   │  (ingress)      │        │  (egress)       │                            │
│   └────────┬────────┘        └────────┬────────┘                            │
│            │                          │                                      │
│            ▼                          │                                      │
│   ┌─────────────────┐                 │                                      │
│   │   cloudfront    │ ◄───────────────┘                                      │
│   │     (CDN)       │                                                        │
│   └────────┬────────┘                                                        │
│            │                                                                 │
└────────────┼────────────────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 5: SECURITY RULES (DEPLOY LAST)                                        │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                     security-rules                                   │   │
│   │   Configures cross-module security group rules for:                 │   │
│   │   - locker ↔ jump-host                                              │   │
│   │   - envoy ↔ jump-host, EKS                                          │   │
│   │   - squid ↔ EKS worker subnets                                      │   │
│   │   - cassandra ↔ jump-host                                           │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│   ⚠️  Must be deployed AFTER all infrastructure components                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Step-by-Step Deployment

#### 1. Bootstrap State Backend

```bash
# Create S3 bucket and DynamoDB table for Terraform state
cd bootstrap/dev
terraform init
terraform apply

# Verify
aws s3 ls | grep hyperswitch-dev-terraform-state
```

#### 2. Deploy VPC Network

```bash
cd live/dev/eu-central-1/vpc-network

# Update terraform.tfvars with your configuration
vi terraform.tfvars

# Deploy
terraform init
terraform plan
terraform apply

# Note outputs for other components
terraform output
```

#### 3. Deploy Core Services (Parallel)

```bash
# Terminal 1: Database
cd live/dev/eu-central-1/database
terraform init && terraform apply

# Terminal 2: ElastiCache
cd live/dev/eu-central-1/elasticache
terraform init && terraform apply

# Terminal 3: ECR
cd live/dev/eu-central-1/ecr
terraform init && terraform apply

# Terminal 4: Jump Host
cd live/dev/eu-central-1/jump-host
terraform init && terraform apply
```

#### 4. Deploy EKS Cluster

```bash
cd live/dev/eu-central-1/eks

# Update terraform.tfvars with VPC outputs
vi terraform.tfvars

# Deploy (takes 15-20 minutes)
terraform init
terraform plan
terraform apply

# Configure kubectl
aws eks update-kubeconfig --name <cluster-name> --region eu-central-1
```

#### 5. Deploy EKS Kubernetes Resources

```bash
cd live/dev/eu-central-1/eks-kubernetes-resources

# Update terraform.tfvars with EKS outputs
vi terraform.tfvars

terraform init && terraform apply
```

#### 6. Deploy Apps Layer

```bash
# Deploy in order (or use ArgoCD for GitOps)
cd live/dev/eu-central-1/apps

# Core infrastructure apps first
cd alb-controller && terraform init && terraform apply
cd ../istio && terraform init && terraform apply
cd ../external-secrets-operator && terraform init && terraform apply

# Then application workloads
cd ../hyperswitch-app && terraform init && terraform apply
cd ../grafana && terraform init && terraform apply
```

#### 7. Deploy Proxy Layer

```bash
# Envoy Proxy (ingress)
cd live/dev/eu-central-1/envoy-proxy
terraform init && terraform apply

# Squid Proxy (egress)
cd ../squid-proxy
terraform init && terraform apply
```

#### 8. Deploy CloudFront

```bash
cd live/dev/eu-central-1/cloudfront

# Update config.yaml with origin DNS from envoy-proxy
vi config.yaml

terraform init && terraform apply
```

#### 9. Deploy Security Rules (LAST)

```bash
cd live/dev/eu-central-1/security-rules

# This reads state from other components via terraform_remote_state
terraform init && terraform apply
```

---

## Environment Configuration

### Directory Structure

```
terraform/aws/
├── ARCHITECTURE.md          # This file
├── README.md                # Deployment guide
├── bootstrap/               # State backend infrastructure
│   ├── dev/
│   ├── integ/
│   ├── prod/
│   └── sandbox/
├── modules/
│   ├── base/                # Layer 1: Atomic AWS resources
│   ├── composition/         # Layer 2: Service compositions
│   ├── application-resources/  # Layer 3: EKS applications
│   └── cloudfront-resources/   # Layer 4: CloudFront shared
└── live/                    # Environment deployments
    ├── dev/
    │   └── eu-central-1/
    │       ├── vpc-network/
    │       ├── eks/
    │       ├── database/
    │       ├── cloudfront/
    │       ├── security-rules/
    │       └── apps/
    ├── integ/
    ├── prod/
    └── sandbox/
```

### Environment Variables

Each component requires a `terraform.tfvars` file. Copy from example and update:

```bash
cd live/dev/eu-central-1/vpc-network
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars
```

### Remote State References

Components fetch outputs from dependencies using `terraform_remote_state`:

```hcl
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "hyperswitch-dev-terraform-state"
    key    = "dev/eu-central-1/vpc-network/terraform.tfstate"
    region = "eu-central-1"
  }
}

# Use outputs
vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
```

---

## Common Operations

### Update Squid Whitelist

```bash
cd live/dev/eu-central-1/squid-proxy

# Edit whitelist
echo ".example.com" >> config/whitelist.txt

# Apply changes (triggers instance refresh)
terraform apply
```

### Scale EKS Node Group

```bash
cd live/dev/eu-central-1/eks

# Edit terraform.tfvars
# node_groups = { ... desired_size = 5 ... }

terraform apply
```

### Add CloudFront Cache Invalidation

```bash
cd live/dev/eu-central-1/cloudfront

# Update version in config.yaml
# invalidation:
#   version: "v1.0.1"  # Increment to trigger invalidation

terraform apply
```

### View Component Outputs

```bash
cd live/dev/eu-central-1/eks
terraform output

# Specific output
terraform output -raw cluster_endpoint
```

---

## Troubleshooting

### State Locked

```bash
# Find lock ID in error message
terraform force-unlock <lock-id>
```

### Instance Unhealthy (ASG)

1. Check CloudWatch logs
2. Verify security group rules
3. Check S3 config bucket access
4. Verify IAM role permissions

### EKS Node Not Ready

1. Check node security group
2. Verify VPC endpoints (ECR, S3, SSM)
3. Check IAM role for node group
4. Review CloudWatch Container Insights

### Database Connection Issues

1. Verify security group allows traffic from source
2. Check subnet group configuration
3. Verify VPC routing (NAT for outbound)

### CloudFront 502 Error

1. Verify origin (Envoy ALB) is healthy
2. Check origin protocol policy
3. Verify security group allows CloudFront IPs

---

## Version Requirements

| Tool | Version |
|------|---------|
| Terraform | >= 1.0 |
| AWS Provider | ~> 5.0 |
| kubectl | >= 1.28 |
| Helm | >= 3.0 |

---

## Additional Documentation

- [Architecture Documentation](./ARCHITECTURE.md) - Complete architecture reference
- [Bootstrap README](./bootstrap/README.md) - State backend setup guide
- [VPC Network README](./live/dev/eu-central-1/vpc-network/README.md) - VPC configuration
- [CloudFront README](./live/dev/eu-central-1/cloudfront/README.md) - CDN configuration
- [Locker README](./live/dev/eu-central-1/locker/README.md) - Card vault deployment

---

## Support

For issues and questions:
1. Check troubleshooting section above
2. Review component-specific README files
3. Consult [ARCHITECTURE.md](./ARCHITECTURE.md) for design details
