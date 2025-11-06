# VPC Network Composition Module

## Overview

This comprehensive Terraform module creates a production-ready, multi-tier VPC network architecture on AWS with built-in security best practices. It's designed for enterprise-level applications requiring:

- **High Availability**: Multi-AZ deployment across 3 availability zones
- **Security**: Network segmentation with NACLs, security groups, and VPC endpoints
- **Scalability**: Support for extensive workloads including large EKS clusters
- **Flexibility**: Configurable subnet tiers for various service types
- **Cost Optimization**: VPC endpoints to reduce NAT gateway costs

## Architecture

### Network Layers

The module creates a layered network architecture:

```
┌─────────────────────────────────────────────────────────────────┐
│                         VPC (10.0.0.0/16)                        │
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Public Tier (Internet-facing)                                │ │
│ │ - Load Balancers, NAT Gateways, Bastion Hosts              │ │
│ │ - Internet Gateway attached                                  │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Private Tier (NAT Gateway access)                           │ │
│ │ - Application servers, EKS workers, Lambda                  │ │
│ │ - Outbound internet via NAT Gateway                         │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Database Tier (Isolated)                                    │ │
│ │ - RDS, Aurora, DocumentDB                                   │ │
│ │ - No internet access                                        │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Cache Tier (Isolated)                                       │ │
│ │ - ElastiCache (Redis, Memcached)                           │ │
│ │ - No internet access                                        │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Custom Tiers (Configurable)                                 │ │
│ │ - Proxy, Service, Data, Management, EKS Control Plane       │ │
│ │ - Flexible routing: public, private-nat, or isolated        │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Security Features

1. **Network ACLs (NACLs)**: Stateless firewall rules at subnet level
   - Public NACL: Allows HTTP/HTTPS, SSH (restrictable), ephemeral ports
   - Private NACL: Allows VPC traffic, HTTPS/HTTP outbound
   - Database NACL: Only allows database ports from VPC
   - Cache NACL: Only allows cache ports from VPC

2. **Security Groups**: Stateful firewall rules at instance level
   - VPC Endpoint SG: Allows HTTPS from VPC

3. **VPC Endpoints**: Private connectivity to AWS services
   - **Gateway Endpoints**: S3, DynamoDB (free)
   - **Interface Endpoints**: EC2, ECR, CloudWatch, Secrets Manager, etc.
   - Reduces NAT gateway costs and improves security

4. **VPC Flow Logs**: Network traffic monitoring for security analysis

## CIDR Strategy

### Recommended Production Setup

For production environments with extensive scalability requirements:

```
Primary VPC CIDR:    10.0.0.0/16    (65,536 IPs - infrastructure)
Secondary CIDR 1:    10.1.0.0/16    (65,536 IPs - EKS pods)
Secondary CIDR 2:    10.2.0.0/16    (65,536 IPs - additional EKS or expansion)
Secondary CIDR 3:    10.3.0.0/16    (65,536 IPs - future expansion)
────────────────────────────────────────────────────────────────
Total:               ~262,000 IPs
```

### Primary VPC Allocation (10.0.0.0/16)

```
Tier                    CIDR Range          Subnets         Total IPs
─────────────────────────────────────────────────────────────────────
Public (DMZ)            10.0.0.0/20         16 x /24        4,096
Private (App/EKS)       10.0.16.0/20        8 x /22         4,096
Database                10.0.64.0/22        4 x /24         1,024
ElastiCache             10.0.72.0/22        4 x /24         1,024
Proxy Layer             10.0.48.0/21        8 x /24         2,048
Management              10.0.80.0/21        8 x /24         2,048
Service Layer           10.0.32.0/21        8 x /24         2,048
Utils/Lambda            10.0.40.0/21        8 x /24         2,048
EKS Control Plane       10.0.56.0/22        4 x /24         1,024
Data Stack              10.0.88.0/21        8 x /24         2,048
Locker (PCI-DSS)        10.0.96.0/21        8 x /24         2,048
Reserved                10.0.128.0/17       -               32,768
─────────────────────────────────────────────────────────────────────
Total                                                       65,536
```

### Why This Strategy?

1. **Separation of Concerns**: Infrastructure vs. workload (pods) networking
2. **EKS Compatibility**: Secondary CIDRs perfect for pod networking
3. **Future-Proof**: Ample room for growth without re-architecting
4. **Best Practice**: Aligns with AWS Well-Architected Framework
5. **Multi-Cluster Ready**: Can support multiple EKS clusters

## Usage

### Basic Example

```hcl
module "vpc_network" {
  source = "../../modules/composition/vpc-network"

  vpc_name           = "my-app-vpc"
  vpc_cidr           = "10.0.0.0/16"
  aws_region         = "eu-central-1"
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

  # Public subnets
  public_subnet_cidrs = [
    "10.0.0.0/24",
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  # Private subnets
  private_subnet_cidrs = [
    "10.0.8.0/22",
    "10.0.12.0/22",
    "10.0.16.0/22"
  ]

  # Database subnets
  database_subnet_cidrs = [
    "10.0.64.0/24",
    "10.0.65.0/24",
    "10.0.66.0/24"
  ]

  # Enable NAT Gateway (one per AZ for HA)
  enable_nat_gateway = true
  single_nat_gateway = false

  # VPC Endpoints
  gateway_vpc_endpoints = ["s3", "dynamodb"]
  interface_vpc_endpoints = ["ec2", "ecr_api", "ecr_dkr", "logs"]

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

### Advanced Example with Custom Subnets

```hcl
module "vpc_network" {
  source = "../../modules/composition/vpc-network"

  vpc_name           = "hyperswitch-prod-vpc"
  vpc_cidr           = "10.0.0.0/16"
  aws_region         = "eu-central-1"
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

  # Secondary CIDRs for EKS pod networking
  secondary_cidr_blocks = [
    "10.1.0.0/16",
    "10.2.0.0/16"
  ]

  # Standard subnet tiers
  public_subnet_cidrs   = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.8.0/21", "10.0.16.0/21", "10.0.24.0/21"]
  database_subnet_cidrs = ["10.0.64.0/24", "10.0.65.0/24", "10.0.66.0/24"]
  elasticache_subnet_cidrs = ["10.0.72.0/24", "10.0.73.0/24", "10.0.74.0/24"]

  # Custom subnets for specific services
  custom_subnet_groups = {
    "proxy-a" = {
      cidr_block        = "10.0.48.0/24"
      availability_zone = "eu-central-1a"
      tier              = "proxy"
      type              = "private-nat"
      create_nat_route  = true
    }
    "eks-control-a" = {
      cidr_block        = "10.0.56.0/24"
      availability_zone = "eu-central-1a"
      tier              = "eks-control-plane"
      type              = "private-isolated"
    }
  }

  # NAT Gateway configuration
  enable_nat_gateway = true
  single_nat_gateway = false  # One NAT per AZ for HA

  # Network ACLs
  create_public_nacl   = true
  create_private_nacl  = true
  create_database_nacl = true

  # VPC Endpoints
  gateway_vpc_endpoints = ["s3", "dynamodb"]
  interface_vpc_endpoints = [
    "ec2", "ecr_api", "ecr_dkr", "logs", "secretsmanager",
    "ssm", "kms", "lambda", "sns", "sqs"
  ]

  # VPC Flow Logs
  enable_flow_logs           = true
  flow_logs_destination_arn  = "arn:aws:s3:::my-flow-logs-bucket"
  flow_logs_destination_type = "s3"

  tags = {
    Environment = "production"
    Project     = "hyperswitch"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_name | Name of the VPC | `string` | - | yes |
| vpc_cidr | The IPv4 CIDR block for the VPC | `string` | - | yes |
| aws_region | AWS region for VPC endpoints | `string` | - | yes |
| availability_zones | List of availability zones | `list(string)` | - | yes |
| secondary_cidr_blocks | Secondary CIDR blocks (for EKS pods) | `list(string)` | `[]` | no |
| public_subnet_cidrs | CIDR blocks for public subnets | `list(string)` | `[]` | no |
| private_subnet_cidrs | CIDR blocks for private subnets | `list(string)` | `[]` | no |
| database_subnet_cidrs | CIDR blocks for database subnets | `list(string)` | `[]` | no |
| elasticache_subnet_cidrs | CIDR blocks for ElastiCache subnets | `list(string)` | `[]` | no |
| enable_nat_gateway | Enable NAT Gateways | `bool` | `true` | no |
| single_nat_gateway | Use single NAT Gateway (cost savings) | `bool` | `false` | no |
| gateway_vpc_endpoints | Gateway endpoints to create | `list(string)` | `[]` | no |
| interface_vpc_endpoints | Interface endpoints to create | `list(string)` | `[]` | no |
| enable_flow_logs | Enable VPC Flow Logs | `bool` | `false` | no |

See [variables.tf](./variables.tf) for complete input documentation.

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_cidr_block | The CIDR block of the VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| database_subnet_ids | List of database subnet IDs |
| nat_gateway_ids | List of NAT Gateway IDs |
| nat_gateway_public_ips | Public IPs of NAT Gateways |

See [outputs.tf](./outputs.tf) for complete output documentation.

## Cost Considerations

### NAT Gateway Costs

- **Dev/Staging**: Use `single_nat_gateway = true` (~$35/month)
- **Production**: Use `single_nat_gateway = false` (~$105/month for 3 AZs)

### VPC Endpoint Costs

- **Gateway Endpoints** (S3, DynamoDB): FREE
- **Interface Endpoints**: ~$7.50/month per endpoint + data transfer

**Cost Savings**: VPC endpoints can reduce NAT Gateway data transfer costs by 70-90% for AWS service traffic.

## Security Best Practices

1. **Enable VPC Flow Logs** in production for security monitoring
2. **Use separate subnets** for different tiers (database, cache, app)
3. **Implement Network ACLs** for defense in depth
4. **Use VPC Endpoints** to avoid internet traffic for AWS services
5. **Enable encryption** for VPC Flow Logs
6. **Restrict public subnets** to load balancers and NAT gateways only
7. **Use private subnets** for all application workloads
8. **Implement bastion hosts** in management subnets for SSH access

## EKS Integration

### Subnet Tagging

For EKS clusters, the module automatically adds tags when enabled:

- **Public subnets**: `kubernetes.io/role/elb = 1` (for external load balancers)
- **Private subnets**: `kubernetes.io/role/internal-elb = 1` (for internal load balancers)

Enable with:
```hcl
public_subnet_enable_eks_elb_tag           = true
private_subnet_enable_eks_internal_elb_tag = true
```

### Pod Networking

Use secondary CIDR blocks for EKS pod networking:

```hcl
secondary_cidr_blocks = [
  "10.1.0.0/16",  # 65,536 IPs for pods
  "10.2.0.0/16"   # Additional cluster or expansion
]
```

## Examples

See the [examples](../../../live/) directory for:

- [Development Environment](../../../live/dev/eu-central-1/vpc-network/)
- [Production Environment](../../../live/prod/eu-central-1/vpc-network/)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| aws | >= 5.0 |

## Authors

Created and maintained by the Hyperswitch DevOps team.

## License

See LICENSE file in repository root.
