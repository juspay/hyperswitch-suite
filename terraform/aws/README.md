# Hyperswitch Terraform Infrastructure

Industry-standard, modular Terraform infrastructure for Hyperswitch Suite proxy services (Squid & Envoy).

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Directory Structure](#directory-structure)
- [Module Design Philosophy](#module-design-philosophy)
- [Getting Started](#getting-started)
- [Terraform Concepts Used](#terraform-concepts-used)
- [Deployment Guide](#deployment-guide)
- [State Management](#state-management)
- [Best Practices](#best-practices)

---

## Architecture Overview

This infrastructure follows a **three-layer architecture**:

### Layer 1: Base Modules (`modules/base/`)
**Purpose**: Atomic, reusable AWS resource wrappers

- Generic building blocks (ASG, security groups, IAM roles, etc.)
- No business logic - just AWS resource abstractions
- Shared across all services and environments
- **You never run terraform here** - these are libraries

**Example**: The `asg` module can be used by squid-proxy, envoy-proxy, nginx, or any other service that needs an Auto Scaling Group.

### Layer 2: Composition Modules (`modules/composition/`)
**Purpose**: Service-specific orchestration of base modules

- Combines multiple base modules to create a complete service
- Contains service-specific business logic (ports, configurations, userdata)
- Implements the "how" for deploying a specific service
- **You never run terraform here** - these are templates

**Example**: The `squid-proxy` module orchestrates ASG + Target Group + Security Groups + IAM + S3 to create a complete Squid proxy service.

### Layer 3: Live Environments (`live/`)
**Purpose**: Actual deployments with environment-specific values

- Contains concrete values for each environment (dev, integ, prod, sandbox)
- References composition modules with specific configuration
- Manages state files (one per deployment)
- **This is where you run terraform** - `terraform apply` happens here

**Example**: `live/dev/eu-central-1/squid-proxy/` deploys a Squid proxy in dev environment using the squid-proxy composition module.

### Benefits

- **DRY Principle**: No code duplication across layers
- **Modularity**: Change one base module, update all services automatically
- **Blast Radius Control**: Isolated state files per deployment (each `live/` directory)
- **Regional Isolation**: Independent deployments per region
- **Environment Isolation**: Dev, Integ, Prod, Sandbox completely separated
- **Testability**: Test base modules → composition modules → live deployments

---

## Directory Structure

```
terraform/aws/
├── modules/
│   ├── base/                           # Layer 1: Atomic, reusable modules
│   │   ├── asg/                        # Auto Scaling Group
│   │   ├── target-group/               # Target Group (ALB/NLB)
│   │   ├── security-group/             # Security Group with rules
│   │   ├── iam-role/                   # IAM Role with policies
│   │   ├── s3-bucket/                  # S3 Bucket with encryption
│   │   └── launch-template/            # EC2 Launch Template
│   │
│   └── composition/                    # Layer 2: Service compositions
│       ├── squid-proxy/                # Squid proxy (uses base modules)
│       └── envoy-proxy/                # Envoy proxy (uses base modules)
│
└── live/                               # Layer 3: Actual deployments
    ├── dev/
    │   └── eu-central-1/
    │       ├── squid-proxy/            # ← Run terraform apply here
    │       └── envoy-proxy/            # ← Run terraform apply here
    ├── integ/
    │   └── eu-central-1/
    │       ├── squid-proxy/
    │       └── envoy-proxy/
    ├── prod/
    │   └── eu-central-1/
    │       └── (TODO)
    └── sandbox/
        └── eu-central-1/
            └── (TODO)
```

---

## Module Design Philosophy

### Base Modules

**Purpose**: Generic, reusable AWS resource abstractions

**Example**: `modules/base/asg/`

- Used by: squid-proxy, envoy-proxy, nginx-proxy, custom apps
- Input: Generic parameters (instance type, min/max size, etc.)
- Output: Resource IDs/ARNs for dependency management

**When to create a base module:**
- The resource will be used by multiple services
- You want to enforce standards (e.g., always encrypt EBS volumes)
- You want to reduce boilerplate

### Composition Modules

**Purpose**: Service-specific orchestration of base modules

**Example**: `modules/composition/squid-proxy/`

- Combines: ASG + Target Group + Security Groups + IAM + S3 + Launch Template
- Implements: Squid-specific logic, userdata, configurations
- Output: Service-level outputs (NLB DNS, ASG name, etc.)

**When to create a composition module:**
- You're deploying a complete service
- The service has specific requirements (ports, configs, etc.)
- You want to deploy the same service across multiple environments

---

## Getting Started

### Prerequisites

1. **Terraform** >= 1.5.0
2. **AWS CLI** configured with credentials
3. **VPC** created (or use default VPC for testing)
4. **S3 Bucket** for state storage (integ/prod only)
5. **DynamoDB Table** for state locking (integ/prod only)

### Quick Start: Deploy Squid Proxy in Dev

```bash
# 1. Navigate to the deployment directory
cd live/dev/eu-central-1/squid-proxy/

# 2. Edit terraform.tfvars with your actual values
vim terraform.tfvars
# Update: vpc_id, subnet_ids, eks_security_group_id, ami_id, config_bucket_name

# 3. Initialize Terraform
terraform init

# 4. Preview changes
terraform plan

# 5. Apply (create infrastructure)
terraform apply

# 6. View outputs
terraform output
```

### Deploy Envoy Proxy

```bash
cd live/dev/eu-central-1/envoy-proxy/
# Follow same steps as above
```

---

## Terraform Concepts Used

### 1. Implicit Dependencies

Terraform automatically creates dependencies when you reference resource attributes:

```hcl
# ASG automatically depends on Launch Template
module "asg" {
  source = "../../base/asg"

  launch_template_id = module.launch_template.lt_id  # ← Implicit dependency
}
```

**Result**: Launch Template is created before ASG

### 2. Explicit Dependencies

Use `depends_on` when dependencies aren't expressed through attributes:

```hcl
resource "aws_autoscaling_group" "example" {
  # ...
  depends_on = [aws_s3_object.config_files]  # ← Explicit dependency
}
```

### 3. Variables with Validation

Enforce constraints at input time:

```hcl
variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "integ", "prod"], var.environment)
    error_message = "Must be dev, integ, or prod"
  }
}
```

### 4. Locals for DRY

Compute values once, reuse everywhere:

```hcl
locals {
  name_prefix = "${var.environment}-${var.project_name}-squid"

  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}
```

### 5. Dynamic Blocks

Iterate over complex nested structures:

```hcl
dynamic "tag" {
  for_each = var.common_tags
  content {
    key   = tag.key
    value = tag.value
  }
}
```

### 6. Conditional Expressions

Environment-specific logic:

```hcl
instance_type = var.environment == "prod" ? "t3.large" : "t3.small"
enable_deletion_protection = var.environment == "prod" ? true : false
```

### 7. Templatefile Function

Generate dynamic configuration files:

```hcl
locals {
  userdata = templatefile("${path.module}/templates/userdata.sh.tpl", {
    config_bucket = var.config_bucket_name
    environment   = var.environment
  })
}
```

---

## Deployment Guide

### Deployment Order

1. **VPC** (foundational networking)
2. **Shared Resources** (load balancers, DNS, etc.)
3. **Service Deployments** (squid, envoy - can be parallel)
4. **Application Layer** (EKS, databases, etc.)

### Environment-Specific Configurations

#### Dev Environment

- **Backend**: Local (state file on disk)
- **Instance Type**: t3.small
- **ASG Size**: min=1, max=2, desired=1
- **Monitoring**: Disabled (cost savings)
- **Deletion Protection**: Disabled

```bash
cd live/dev/eu-central-1/squid-proxy/
terraform apply
```

#### Integ Environment

- **Backend**: S3 (shared state)
- **Instance Type**: t3.medium
- **ASG Size**: min=1, max=3, desired=2
- **Monitoring**: Enabled
- **Deletion Protection**: Disabled

```bash
cd live/integ/eu-central-1/squid-proxy/
terraform init  # Prompts for S3 backend config
terraform apply
```

#### Prod Environment

- **Backend**: S3 (shared state, encrypted)
- **Instance Type**: t3.large
- **ASG Size**: min=2, max=6, desired=2
- **Monitoring**: Enabled with alarms
- **Deletion Protection**: Enabled

```bash
cd live/prod/eu-central-1/squid-proxy/
terraform init
terraform plan -out=tfplan
# Review carefully!
terraform apply tfplan
```

---

## State Management

### State File Isolation

Each deployment has its **own state file**:

```
S3: hyperswitch-terraform-state/
├── dev/eu-central-1/squid-proxy/terraform.tfstate      # Separate
├── dev/eu-central-1/envoy-proxy/terraform.tfstate      # Separate
├── integ/eu-central-1/squid-proxy/terraform.tfstate    # Separate
└── prod/eu-central-1/squid-proxy/terraform.tfstate     # Separate
```

### Benefits

✅ **Blast Radius**: Destroying one doesn't affect others
✅ **Parallelism**: Multiple teams can work simultaneously
✅ **Speed**: Smaller state = faster plan/apply
✅ **Security**: Different IAM permissions per environment

### Setting Up S3 Backend

```bash
# 1. Create S3 bucket
aws s3 mb s3://hyperswitch-terraform-state --region eu-central-1

# 2. Enable versioning
aws s3api put-bucket-versioning \
  --bucket hyperswitch-terraform-state \
  --versioning-configuration Status=Enabled

# 3. Enable encryption
aws s3api put-bucket-encryption \
  --bucket hyperswitch-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# 4. Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-central-1
```

---

## Best Practices

### 1. Never Run Terraform in modules/ Directory

❌ **Wrong**:
```bash
cd modules/composition/squid-proxy/
terraform apply  # This will fail!
```

✅ **Correct**:
```bash
cd live/dev/eu-central-1/squid-proxy/
terraform apply  # This works!
```

### 2. Always Use terraform plan First

```bash
terraform plan -out=tfplan
# Review the plan carefully
terraform apply tfplan
```

### 3. Use Workspaces for Development (Optional)

```bash
terraform workspace new feature-xyz
terraform workspace select feature-xyz
terraform apply
```

### 4. Tag Everything

Tags enable cost tracking, automation, and organization:

```hcl
common_tags = {
  Environment = "production"
  Project     = "hyperswitch"
  ManagedBy   = "terraform"
  Team        = "platform"
  CostCenter  = "engineering"
}
```

### 5. Use Remote State References

Access outputs from other deployments:

```hcl
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "hyperswitch-terraform-state"
    key    = "prod/eu-central-1/vpc/terraform.tfstate"
    region = "eu-central-1"
  }
}

# Use outputs
vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
```

### 6. Protect Production

Enable deletion protection:

```hcl
enable_deletion_protection = var.environment == "prod" ? true : false
```

### 7. Version Pin for Stability

```hcl
terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Allow minor updates, not major
    }
  }
}
```

---

## Common Commands

```bash
# Initialize
terraform init

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show outputs
terraform output

# Show state
terraform show

# List resources
terraform state list

# Destroy infrastructure
terraform destroy

# Import existing resource
terraform import aws_instance.example i-1234567890abcdef0
```

---

## Troubleshooting

### Issue: State locked

```bash
# View lock info
terraform force-unlock <LOCK_ID>
```

### Issue: Module not found

```bash
# Re-initialize to download modules
terraform init -upgrade
```

### Issue: Provider version conflict

```bash
# Upgrade providers
terraform init -upgrade

# Or lock to specific version in versions.tf
```

---

## Contributing

1. Create a feature branch
2. Make changes to modules or live configs
3. Run `terraform fmt -recursive`
4. Run `terraform validate`
5. Test in dev environment first
6. Create pull request

---

## Security Considerations

- ✅ IMDSv2 enforced on all instances
- ✅ EBS volumes encrypted by default
- ✅ S3 buckets encrypted (AES256)
- ✅ Security groups follow least privilege
- ✅ IAM roles follow least privilege
- ✅ No hardcoded credentials
- ✅ State files encrypted in S3

---

## Cost Optimization

### Dev Environment
- Use t3.small instances
- Disable detailed monitoring
- Shorter log retention (7-30 days)
- Auto-shutdown during off-hours (optional)

### Prod Environment
- Right-size instances based on metrics
- Use Savings Plans or Reserved Instances
- Enable S3 Intelligent Tiering
- 90-day log retention

---

## Support

For questions or issues:
- Check the module README files
- Review Terraform documentation
- Open an issue in the repository

---

## License

Internal use only - Hyperswitch Suite
