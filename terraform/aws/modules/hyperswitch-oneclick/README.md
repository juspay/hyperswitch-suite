# Hyperswitch One-Click Deployment Module

A simplified, opinionated Terraform module for deploying Hyperswitch on AWS EKS with minimal configuration.

## Architecture

```
VPC → EKS Cluster → Node Group → Helm Deployment (Hyperswitch Stack)
```

## Components Created

| Component | Resources |
|-----------|-----------|
| **Networking** | VPC, 2 public subnets, 2 private subnets, Internet Gateway, NAT Gateway, Route Tables |
| **IAM** | Cluster role, Node role, EBS CSI driver role (Pod Identity) |
| **EKS** | Kubernetes cluster (v1.35), managed node group |
| **Addons** | VPC CNI, CoreDNS, kube-proxy, EBS CSI Driver, Pod Identity Agent |
| **Storage** | GP3 storage class (default) |
| **Hyperswitch** | Helm release with hyperswitch-stack chart |

## Quick Start

### Prerequisites

- Terraform >= 1.0
- AWS CLI configured with credentials
- kubectl (optional, for accessing the cluster)

### Usage

1. Create a new Terraform configuration:

```hcl
module "hyperswitch" {
  source = "./terraform/aws/modules/hyperswitch-oneclick"

  aws_region   = "us-east-1"
  project_name = "hyperswitch"
  environment  = "dev"

  vpc_cidr = "10.0.0.0/16"

  cluster_version = "1.35"

  node_group = {
    capacity_type              = "ON_DEMAND"
    instance_types             = ["t3.medium"]
    desired_size               = 4
    min_size                   = 2
    max_size                   = 10
    max_unavailable_percentage = 33
    labels                     = {}
  }

  tags = {
    Team = "platform"
  }
}
```

2. Initialize and apply:

```bash
terraform init
terraform apply
```

3. Configure kubectl:

```bash
aws eks update-kubeconfig --name <cluster-name> --region <region>
```

4. Access Hyperswitch services:

```bash
kubectl port-forward service/hyperswitch-server 8080:80 -n hyperswitch &
kubectl port-forward service/hyperswitch-control-center 9000:80 -n hyperswitch &
kubectl port-forward service/hyperswitch-web 9050:9050 -n hyperswitch &
```

## Configuration

### Minimal Configuration

```hcl
module "hyperswitch" {
  source = "./terraform/aws/modules/hyperswitch-oneclick"

  aws_region   = "us-east-1"
  environment  = "dev"
}
```

### Production Configuration

```hcl
module "hyperswitch" {
  source = "./terraform/aws/modules/hyperswitch-oneclick"

  aws_region   = "us-east-1"
  project_name = "hyperswitch"
  environment  = "prod"

  vpc_cidr = "10.0.0.0/16"

  availability_zones = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c"
  ]

  cluster_version = "1.35"

  cluster_endpoint_public_access_cidrs = [
    "10.0.0.0/8",
    "192.168.0.0/16"
  ]

  node_group = {
    capacity_type              = "ON_DEMAND"
    instance_types             = ["m5.large", "m5.xlarge"]
    desired_size               = 6
    min_size                   = 4
    max_size                   = 20
    max_unavailable_percentage = 25
    labels = {
      environment = "production"
    }
  }

  tags = {
    Team    = "platform"
    CostCenter = "payments"
  }
}
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `project_name` | Project name for resource naming | `hyperswitch` |
| `environment` | Environment name | `dev` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `cluster_version` | Kubernetes version | `1.35` |
| `node_group` | Node group configuration | See defaults |
| `hyperswitch_namespace` | Kubernetes namespace | `hyperswitch` |
| `hyperswitch_helm_values` | Custom Helm values | `{}` |

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | EKS cluster endpoint |
| `vpc_id` | VPC ID |
| `configure_kubectl` | Command to configure kubectl |
| `port_forward_commands` | Commands to access services |

## Customizing Hyperswitch

### Custom Helm Values

```hcl
module "hyperswitch" {
  source = "./terraform/aws/modules/hyperswitch-oneclick"

  hyperswitch_helm_values = {
    "server.replicaCount"    = "3"
    "server.resources.requests.cpu"    = "500m"
    "server.resources.requests.memory" = "1Gi"
  }
}
```

### Using a Specific Helm Version

```hcl
module "hyperswitch" {
  source = "./terraform/aws/modules/hyperswitch-oneclick"

  hyperswitch_helm_version = "1.0.0"
}
```

## Cost Estimate

### Development (default settings)

| Resource | Configuration | Est. Monthly Cost |
|----------|---------------|-------------------|
| NAT Gateway | 1x | ~$35 |
| EKS Cluster | 1x | ~$75 |
| EC2 (t3.medium x4) | 4 nodes | ~$120 |
| **Total** | | ~$230/month |

### Production

| Resource | Configuration | Est. Monthly Cost |
|----------|---------------|-------------------|
| NAT Gateway | 1x | ~$35 |
| EKS Cluster | 1x | ~$75 |
| EC2 (m5.large x6) | 6 nodes | ~$300 |
| **Total** | | ~$410/month |

## Cleanup

```bash
terraform destroy
```

## Limitations

- Single NAT Gateway (not highly available)
- 2 availability zones only
- No Aurora PostgreSQL (uses in-cluster database)
- No ElastiCache Redis (uses in-cluster Redis)
- No dedicated card vault (Locker)

For production deployments with full HA, consider using the [full Terraform suite](../README.md).

## Related

- [Full Terraform Suite](../README.md) - Complete modular infrastructure
- [Architecture Documentation](../ARCHITECTURE.md) - Detailed architecture
- [Hyperswitch Helm Chart](https://github.com/juspay/hyperswitch-helm)
