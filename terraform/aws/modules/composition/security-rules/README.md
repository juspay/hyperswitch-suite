# Security Rules Module

This module manages cross-module security group rules for the Hyperswitch infrastructure. Security groups are created in their respective composition modules, while connectivity rules between modules are centralized here.

## Table of Contents

- [Overview](#overview)
- [Architecture Decision](#architecture-decision)
- [Deployment Order](#deployment-order)
- [Migration Guide](#migration-guide)
- [Adding New Modules](#adding-new-modules)
- [Troubleshooting](#troubleshooting)

---

## Overview

### Design Pattern

**Security Group Creation**: Each composition module (locker, envoy-proxy, jump-host, etc.) creates its own security groups and outputs the SG IDs.

**Rule Management**:
- **Module-internal rules** → Stay in the composition module (e.g., NLB → instance within locker module)
- **Cross-module rules** → Managed by this security-rules module (e.g., jump-host → locker SSH)

### Benefits

1. **Parallel Execution** - Infrastructure modules can deploy simultaneously without circular dependencies
2. **Clean Separation** - Connectivity concerns separated from infrastructure provisioning
3. **Terragrunt Ready** - Perfect for dependency graph management
4. **Change Isolation** - Updating connectivity doesn't touch core infrastructure state

---

## Architecture Decision

### Rule Placement Decision Matrix

Use this simple rule to determine where security group rules should be defined:

| Scenario | Location | Example |
|----------|----------|---------|
| **Cross-module reference** | security-rules module | Jump host → Locker SSH access |
| **Same-module internal** | Composition module | Locker NLB → Locker instance |

#### Examples

**✅ Stays in Composition Module:**
- Locker NLB → Locker instance (port 8080)
- Envoy ALB → Envoy ASG (traffic port)
- Squid NLB health checks → Squid instances

**✅ Moves to Security-Rules Module:**
- Jump host → Locker SSH (cross-module)
- Locker → RDS database (cross-module)
- Jump host → NLB HTTPS (cross-module)
- Any rule referencing SG from another module

---

## Deployment Order

### Initial Deployment

When deploying from scratch, follow this order:

```
1. Infrastructure Modules (can run in parallel):
   ├── vpc-network
   ├── jump-host
   ├── eks
   ├── locker
   ├── envoy-proxy
   └── squid-proxy

2. Security Rules Module:
   └── security-rules (depends on all infrastructure modules)
```

### Example Deployment Commands

```bash
# Step 1: Deploy infrastructure modules (can be parallelized)
cd terraform/aws/live/dev/eu-central-1/locker
terraform init
terraform apply

cd ../jump-host
terraform init
terraform apply

# ... repeat for other infrastructure modules

# Step 2: Deploy security rules (MUST be after infrastructure)
cd ../security-rules
terraform init
terraform apply
```

### With Terragrunt

```hcl
# terragrunt.hcl example
dependencies {
  paths = [
    "../locker",
    "../jump-host",
    "../eks",
    "../envoy-proxy"
  ]
}
```

---

## Migration Guide

This guide helps you migrate existing security group rules from composition modules to the security-rules module.

### Prerequisites

- ✅ All infrastructure modules deployed and stable
- ✅ State files backed up
- ✅ Terraform >= 1.5.0 installed

### Migration Steps

#### Step 1: Update Composition Module

Remove configurable rule resources and variables from the composition module while keeping automatic (module-internal) rules.

**Example: Locker Module**

In `modules/composition/locker/main.tf`, keep:
```hcl
# ✅ KEEP - Module-internal rule
resource "aws_security_group_rule" "locker_ingress_from_nlb" {
  security_group_id        = local.locker_security_group_id
  type                     = "ingress"
  from_port                = var.locker_port
  to_port                  = var.locker_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nlb.id
  description              = "Allow traffic from NLB to locker instance"
}
```

Remove:
```hcl
# ❌ REMOVE - Configurable cross-module rules
resource "aws_security_group_rule" "locker_ingress_rules" {
  for_each = { for idx, rule in var.locker_ingress_rules : idx => rule }
  # ...
}
```

Remove corresponding variables from `modules/composition/locker/variables.tf`:
```hcl
# ❌ REMOVE
variable "locker_ingress_rules" { ... }
variable "locker_egress_rules" { ... }
variable "nlb_ingress_rules" { ... }
variable "nlb_egress_rules" { ... }
```

#### Step 2: Update Live Layer Configuration

Remove rule variables from `live/dev/eu-central-1/locker/terraform.tfvars` and `variables.tf`.

Remove from `main.tf`:
```hcl
module "locker" {
  # ❌ REMOVE these lines
  locker_ingress_rules = var.locker_ingress_rules
  locker_egress_rules  = var.locker_egress_rules
  nlb_ingress_rules    = var.nlb_ingress_rules
  nlb_egress_rules     = var.nlb_egress_rules
}
```

#### Step 3: Apply Updated Module

```bash
cd terraform/aws/live/dev/eu-central-1/locker
terraform init -upgrade
terraform plan  # Should show rule resources being removed
```

**⚠️ IMPORTANT: Do NOT apply yet!** We need to migrate state first to avoid downtime.

#### Step 4: Deploy Security-Rules Module

```bash
cd ../security-rules
terraform init
terraform plan  # Should show new security group rules being created
terraform apply # Creates security-rules infrastructure
```

#### Step 5: Migrate State

Now we'll move the existing security group rules from locker state to security-rules state using `terraform state mv`.

##### 5.1: List Current Resources

```bash
# In locker directory
cd ../locker
terraform state list | grep security_group_rule
```

Example output:
```
aws_security_group_rule.locker_egress_rules[0]
aws_security_group_rule.locker_egress_rules[1]
aws_security_group_rule.locker_egress_rules[2]
aws_security_group_rule.locker_ingress_rules[0]
aws_security_group_rule.nlb_egress_rules[0]
aws_security_group_rule.nlb_ingress_rules[0]
```

##### 5.2: Pull State Files

Since we're using S3 backend, we'll work with local state copies:

```bash
# Pull locker state
cd ../locker
terraform state pull > locker-state.json

# Pull security-rules state
cd ../security-rules
terraform state pull > security-rules-state.json
```

##### 5.3: Move Resources Between States

Use `terraform state mv` to transfer resources:

```bash
# Move locker ingress rule 0 (SSH from jump host)
terraform state mv \
  -state=../locker/locker-state.json \
  -state-out=security-rules-state.json \
  'aws_security_group_rule.locker_ingress_rules[0]' \
  'module.security_rules.aws_security_group_rule.locker_ingress[0]'

# Move locker egress rule 0 (HTTPS)
terraform state mv \
  -state=../locker/locker-state.json \
  -state-out=security-rules-state.json \
  'aws_security_group_rule.locker_egress_rules[0]' \
  'module.security_rules.aws_security_group_rule.locker_egress[0]'

# Move locker egress rule 1 (HTTP)
terraform state mv \
  -state=../locker/locker-state.json \
  -state-out=security-rules-state.json \
  'aws_security_group_rule.locker_egress_rules[1]' \
  'module.security_rules.aws_security_group_rule.locker_egress[1]'

# Move locker egress rule 2 (PostgreSQL to RDS)
terraform state mv \
  -state=../locker/locker-state.json \
  -state-out=security-rules-state.json \
  'aws_security_group_rule.locker_egress_rules[2]' \
  'module.security_rules.aws_security_group_rule.locker_egress[2]'

# Move NLB ingress rule 0 (HTTPS from jump host)
terraform state mv \
  -state=../locker/locker-state.json \
  -state-out=security-rules-state.json \
  'aws_security_group_rule.nlb_ingress_rules[0]' \
  'module.security_rules.aws_security_group_rule.nlb_ingress[0]'
```

##### 5.4: Push Updated States

```bash
# Push updated locker state
cd ../locker
terraform state push locker-state.json

# Push updated security-rules state
cd ../security-rules
terraform state push security-rules-state.json

# Clean up local state files
rm ../locker/locker-state.json
rm security-rules-state.json
```

#### Step 6: Validate Migration

Verify that no changes are detected after state migration:

```bash
# Check locker module
cd ../locker
terraform plan
# Expected: "No changes. Your infrastructure matches the configuration."

# Check security-rules module
cd ../security-rules
terraform plan
# Expected: "No changes. Your infrastructure matches the configuration."
```

✅ **Success Criteria:**
- Both `terraform plan` commands show **zero changes**
- No resources are being created or destroyed
- All security group rules still exist in AWS

#### Step 7: Final Apply (Safety Check)

Now we can safely apply the updated locker configuration:

```bash
cd ../locker
terraform apply
```

This should show that rule resources are removed from state only (already moved to security-rules).

---

## Adding New Modules

To add security group rules for additional modules (e.g., envoy-proxy, jump-host):

### 1. Add Variables to Security-Rules Module

In `modules/composition/security-rules/variables.tf`:

```hcl
variable "envoy_asg_sg_id" {
  description = "Security group ID of the Envoy ASG"
  type        = string
}

variable "envoy_asg_ingress_rules" {
  description = "Ingress rules for Envoy ASG security group"
  type = list(object({
    # ... same schema as locker rules
  }))
  default = []
  validation { ... }
}
```

### 2. Add Rule Resources

In `modules/composition/security-rules/main.tf`:

```hcl
resource "aws_security_group_rule" "envoy_asg_ingress" {
  for_each = { for idx, rule in var.envoy_asg_ingress_rules : idx => rule }

  security_group_id = var.envoy_asg_sg_id
  type              = "ingress"
  # ... same pattern as locker rules
}
```

### 3. Update Live Layer

In `live/dev/eu-central-1/security-rules/main.tf`:

```hcl
data "terraform_remote_state" "envoy_proxy" {
  backend = "s3"
  config = {
    bucket = "hyperswitch-dev-terraform-state"
    key    = "dev/eu-central-1/envoy-proxy/terraform.tfstate"
    region = "eu-central-1"
  }
}

module "security_rules" {
  # ... existing config

  envoy_asg_sg_id         = data.terraform_remote_state.envoy_proxy.outputs.asg_security_group_id
  envoy_asg_ingress_rules = var.envoy_asg_ingress_rules
}
```

### 4. Add Rule Definitions

In `live/dev/eu-central-1/security-rules/terraform.tfvars`:

```hcl
envoy_asg_ingress_rules = [
  {
    description = "SSH from jump host"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    sg_id       = ["sg-xxxxxxxxxxxxx"]
  }
]
```

---

## Troubleshooting

### Issue: "Error: Resource already exists"

**Cause:** Attempting to create a rule that already exists in AWS.

**Solution:** You likely need to migrate state first. Follow the [Migration Guide](#migration-guide) step 5.

### Issue: "Error: Invalid for_each argument"

**Cause:** The rule list variable is null or incorrectly formatted.

**Solution:** Ensure the variable is defined with `default = []` in both composition and live layer.

### Issue: terraform plan shows destroying and recreating rules

**Cause:** State migration incomplete or incorrect resource addresses.

**Solution:**
1. Run `terraform state list` to verify resource addresses
2. Ensure `for_each` keys match between old and new resources
3. Re-run state migration with correct addresses

### Issue: "No outputs found" when referencing remote state

**Cause:** The infrastructure module hasn't been applied yet or doesn't export required outputs.

**Solution:**
1. Apply the infrastructure module first
2. Verify outputs exist: `cd ../locker && terraform output`
3. Ensure output names match in `data.terraform_remote_state` references

### Issue: Circular dependency between modules

**Cause:** Trying to deploy security-rules before infrastructure modules are complete.

**Solution:** Always deploy infrastructure modules first, security-rules second. See [Deployment Order](#deployment-order).

---

## State Migration Commands Reference

Complete list of commands for migrating locker module (adjust for other modules):

```bash
# Navigate to locker directory
cd terraform/aws/live/dev/eu-central-1/locker

# List all security group rule resources
terraform state list | grep security_group_rule

# Pull states
terraform state pull > locker-state.json
cd ../security-rules
terraform state pull > security-rules-state.json

# Move each rule (update indices based on your terraform state list output)
terraform state mv \
  -state=../locker/locker-state.json \
  -state-out=security-rules-state.json \
  'aws_security_group_rule.locker_ingress_rules[INDEX]' \
  'module.security_rules.aws_security_group_rule.locker_ingress[INDEX]'

# Push updated states
cd ../locker
terraform state push locker-state.json
cd ../security-rules
terraform state push security-rules-state.json

# Validate
cd ../locker && terraform plan
cd ../security-rules && terraform plan

# Clean up
rm ../locker/locker-state.json security-rules-state.json
```

---

## Additional Resources

- [Terraform State Management](https://www.terraform.io/docs/language/state/index.html)
- [Managing Resource Lifecycle](https://www.terraform.io/docs/language/meta-arguments/lifecycle.html)
- [AWS Security Group Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)

---

## Support

For questions or issues with this migration:
1. Review the [Troubleshooting](#troubleshooting) section
2. Check Terraform plan output carefully
3. Ensure all prerequisites are met
4. Verify state files are backed up before migration
