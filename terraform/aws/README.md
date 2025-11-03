# Hyperswitch Terraform Infrastructure

Modular Terraform infrastructure for Hyperswitch proxy services (Squid outbound proxy and Envoy ingress proxy).

## Architecture

Three-layer modular design for reusability and maintainability:

**Layer 1: Base Modules** (`modules/base/`)
- Atomic AWS resource wrappers (ASG, Security Groups, IAM, S3, etc.)
- Generic building blocks with no business logic
- Never run terraform here - these are libraries

**Layer 2: Composition Modules** (`modules/composition/`)
- Service-specific orchestration combining base modules
- `squid-proxy/` - Outbound HTTP/HTTPS proxy with domain whitelisting
- `envoy-proxy/` - Ingress proxy for incoming web traffic
- Never run terraform here - these are templates

**Layer 3: Live Environments** (`live/`)
- Actual deployments with environment-specific values
- This is where you run terraform commands
- Isolated state files per deployment (blast radius control)

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed documentation.

## Quick Start

### Deploy Squid Proxy

```bash
cd live/dev/eu-central-1/squid-proxy

# Update terraform.tfvars with your AWS resource IDs
vi terraform.tfvars

# Deploy
terraform init
terraform plan
terraform apply
```

### Deploy Envoy Proxy

```bash
cd live/dev/eu-central-1/envoy-proxy
vi terraform.tfvars
terraform init && terraform plan && terraform apply
```

## Available Services

### Squid Proxy
- Purpose: HTTP/HTTPS outbound traffic control with domain whitelisting
- Components: NLB + ASG + S3 + Security Groups
- Key Features: Domain whitelist, zero-downtime updates, multi-AZ HA
- Docs: [Testing Guide](../SQUID_PROXY_TESTING_GUIDE.md), [EKS CIDR Support](../SQUID_EKS_CIDR_SUPPORT.md)

### Envoy Proxy
- Purpose: Advanced ingress proxy for incoming traffic
- Components: ALB + ASG + S3 + Security Groups
- Key Features: SSL termination, advanced routing, zero-downtime updates
- Traffic Flow: CloudFront → External ALB → Envoy → Internal ALB → EKS

## Environment Management

**dev/** - Public reference with masked values (vpc-XXXXXXXXXXXXX)
- Small instances (t3.small), minimal capacity (1 instance)
- Local state, detailed documentation
- Use as starting point for new deployments

**integ/** - Integration/UAT (private repo recommended)
- Medium instances, moderate capacity (1-2 instances)
- Remote state (S3 + DynamoDB)
- Copy dev structure and update with actual values

**prod/** - Production (private repo with strict access)
- Larger instances (t3.medium+), HA (2+ instances, multi-AZ)
- Remote state with encryption (S3 + DynamoDB + KMS)
- Code review required, test in lower environments first

**sandbox/** - Experimentation (private repo)
- Minimal resources, can scale to 0
- Ephemeral, cost-optimized

### Setting Up New Environments

```bash
# Copy dev structure
cp -r live/dev/eu-central-1/squid-proxy live/integ/eu-central-1/squid-proxy

# Update configuration
cd live/integ/eu-central-1/squid-proxy
vi terraform.tfvars  # Change environment, replace XXXXXXXXXXXXX with actual values

# Deploy
terraform init && terraform plan && terraform apply
```

## State Management

Each deployment has isolated state files:

```
S3: hyperswitch-terraform-state-{env}
DynamoDB: terraform-state-lock-{env}
```

Remote backend example:

```hcl
terraform {
  backend "s3" {
    bucket         = "hyperswitch-terraform-state-prod"
    key            = "prod/eu-central-1/squid-proxy/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-prod"
    kms_key_id     = "arn:aws:kms:REGION:ACCOUNT:key/KEY-ID"  # Prod only
  }
}
```

Bootstrap state infrastructure: `cd bootstrap/dev && terraform apply`

## Common Tasks

Add domain to Squid whitelist:
```bash
echo ".example.com" >> config/whitelist.txt
terraform apply
```

Scale ASG:
```bash
# Edit terraform.tfvars: desired_capacity, min_size, max_size
terraform apply
```

View outputs:
```bash
terraform output
terraform output -raw squid_nlb_dns_name
```

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Detailed architecture
- [live/README.md](live/README.md) - Environment overview
- [SQUID_PROXY_TESTING_GUIDE.md](../SQUID_PROXY_TESTING_GUIDE.md) - Testing procedures
- Module READMEs in respective directories

## Troubleshooting

**State locked**: `terraform force-unlock <lock-id>` if stuck

**Instance unhealthy**: Check CloudWatch logs, security groups, S3 configs

**NLB target unhealthy**: Verify health check port, security groups, service running

**Squid not blocking**: Check whitelist uploaded to S3, squid.conf references, logs

## Version Requirements

- Terraform >= 1.0
- AWS Provider ~> 5.0
