# VPC Network Configuration Reference

## File Alignment Verification

This document shows how [main.tf](main.tf), [variables.tf](variables.tf), and [terraform.tfvars](terraform.tfvars) align perfectly.

---

## Configuration Flow

```
terraform.tfvars → variables.tf → main.tf → modules/composition/vpc-network
     (values)      (definitions)   (module call)        (implementation)
```

---

## Complete Variable Mapping

### Basic Configuration

| terraform.tfvars | variables.tf | main.tf | Value |
|------------------|--------------|---------|-------|
| `aws_region` | ✅ Defined | ✅ `var.aws_region` | `"eu-central-1"` |
| `vpc_cidr` | ✅ Defined | ✅ `var.vpc_cidr` | `"10.0.0.0/16"` |
| `availability_zones` | ✅ Defined | ✅ `var.availability_zones` | `["eu-central-1a", "eu-central-1b", "eu-central-1c"]` |
| `single_nat_gateway` | ✅ Defined | ✅ `var.single_nat_gateway` | `true` (dev) |
| `secondary_cidr_blocks` | ✅ Defined | ✅ `var.secondary_cidr_blocks` | `[]` (optional) |

---

### Subnet CIDRs (All 12 Types)

#### PUBLIC TIER

| Subnet Type | terraform.tfvars | variables.tf | main.tf | CIDRs |
|-------------|------------------|--------------|---------|-------|
| **External Incoming** | `external_incoming_subnet_cidrs` | ✅ Defined | ✅ Used | `10.0.64-66.0/24` |
| **Management** | `management_subnet_cidrs` | ✅ Defined | ✅ Used | `10.0.67-69.0/24` |

#### PRIVATE WITH NAT TIER

| Subnet Type | terraform.tfvars | variables.tf | main.tf | CIDRs |
|-------------|------------------|--------------|---------|-------|
| **EKS Workers** | `eks_workers_subnet_cidrs` | ✅ Defined | ✅ Used | `10.0.32/21, 40/21, 48/21` ⭐ |
| **Incoming Envoy** | `incoming_envoy_subnet_cidrs` | ✅ Defined | ✅ Used | `10.0.88-90.0/24` |
| **Outgoing Proxy** | `outgoing_proxy_subnet_cidrs` | ✅ Defined | ✅ Used | `10.0.91-93.0/24` |
| **Utils** | `utils_subnet_cidrs` | ✅ Defined | ✅ Used | `10.0.94-96.0/24` |

#### FULLY ISOLATED TIER

| Subnet Type | terraform.tfvars | variables.tf | main.tf | CIDRs |
|-------------|------------------|--------------|---------|-------|
| **EKS Control Plane** | `eks_control_plane_subnet_cidrs` | ✅ Defined | ✅ Used | `10.0.70-72.0/24` |
| **Database** | `database_subnet_cidrs` | ✅ Defined | ✅ Used | `10.0.73-75.0/24` |
| **Locker Database** | `locker_database_subnet_cidrs` | ✅ Defined | ✅ Used | `10.0.76-78.0/24` |
| **Locker Server** | `locker_server_subnet_cidrs` | ✅ Defined | ✅ Used | `10.0.79-81.0/24` |
| **ElastiCache** | `elasticache_subnet_cidrs` | ✅ Defined | ✅ Used | `10.0.82-84.0/24` |
| **Data Stack** | `data_stack_subnet_cidrs` | ✅ Defined | ✅ Used | `10.0.85-87.0/24` |

---

### Additional Configuration

| Setting | terraform.tfvars | variables.tf | main.tf | Value |
|---------|------------------|--------------|---------|-------|
| `enable_vpc_endpoints` | ✅ Set | ✅ Defined | ✅ Used | `true` |
| `enable_flow_logs` | ✅ Set | ✅ Defined | ✅ Used | `false` (dev) |
| `tags` | ✅ Set | ✅ Defined | ✅ Merged | See below |

---

## Tag Configuration

### From terraform.tfvars
```hcl
tags = {
  Environment = "dev"
  Team        = "DevOps"
  CostCenter  = "Engineering"
  ManagedBy   = "Terraform"
  Project     = "hyperswitch"
  Plan        = "optimized-36-subnets"
}
```

### Merged in main.tf
```hcl
tags = merge(
  var.tags,                    # Base tags from terraform.tfvars
  {
    Environment = "dev"        # Additional environment-specific
    ManagedBy   = "Terraform"  # Confirmed managed by Terraform
    Project     = "hyperswitch"
    Plan        = "optimized-36-subnets"
  }
)
```

---

## Security Configuration (Hardcoded in main.tf)

These are **intentionally hardcoded** for security:

| Setting | Value | Reason |
|---------|-------|--------|
| `map_public_ip_on_launch` | `false` | Security: No auto public IPs |
| `enable_eks_elb_tag` | `true` | EKS external load balancers |
| `enable_eks_internal_elb_tag` | `true` | EKS internal load balancers |
| `enable_dns_hostnames` | `true` | Required for VPC |
| `enable_dns_support` | `true` | Required for VPC |
| `create_public_nacl` | `true` | Network ACLs enabled |
| `create_private_nacl` | `true` | Network ACLs enabled |
| `create_database_nacl` | `true` | Network ACLs enabled |
| `create_elasticache_nacl` | `true` | Network ACLs enabled |

---

## VPC Endpoints Configuration

### Gateway Endpoints (Free)
Hardcoded in main.tf:
```hcl
gateway_vpc_endpoints = [
  "s3",
  "dynamodb"
]
```

### Interface Endpoints (Conditional)
Controlled by `enable_vpc_endpoints` variable:
```hcl
interface_vpc_endpoints = var.enable_vpc_endpoints ? [
  "ec2",
  "ecr_api",
  "ecr_dkr",
  "logs",
  "secretsmanager",
  "ssm",
  "ssmmessages",
  "ec2messages",
  "kms"
] : []
```

**When `enable_vpc_endpoints = true`**: All 9 interface endpoints created
**When `enable_vpc_endpoints = false`**: No interface endpoints (gateway endpoints still created)

---

## Validation Checklist

### ✅ All Variables Match

```bash
# Check all subnet variables are defined
grep "subnet_cidrs" terraform.tfvars | wc -l
# Expected: 12 (one for each subnet type)

# Check all variables used in main.tf exist in variables.tf
grep "var\." main.tf | grep subnet_cidrs | wc -l
# Expected: 12 (one for each subnet type)

# Check no old variables remain
grep -E "(public_subnet_cidrs|private_subnet_cidrs)" terraform.tfvars
# Expected: No matches (old variables removed)
```

### ✅ CIDR Blocks Don't Overlap

All CIDR blocks are non-overlapping:
- External Incoming: `10.0.64.0/24` - `10.0.66.0/24` (3 × 256 IPs)
- Management: `10.0.67.0/24` - `10.0.69.0/24` (3 × 256 IPs)
- EKS Workers: `10.0.32.0/21` - `10.0.48.0/21` (3 × 2,048 IPs)
- EKS Control Plane: `10.0.70.0/24` - `10.0.72.0/24` (3 × 256 IPs)
- Database: `10.0.73.0/24` - `10.0.75.0/24` (3 × 256 IPs)
- Locker Database: `10.0.76.0/24` - `10.0.78.0/24` (3 × 256 IPs)
- Locker Server: `10.0.79.0/24` - `10.0.81.0/24` (3 × 256 IPs)
- ElastiCache: `10.0.82.0/24` - `10.0.84.0/24` (3 × 256 IPs)
- Data Stack: `10.0.85.0/24` - `10.0.87.0/24` (3 × 256 IPs)
- Incoming Envoy: `10.0.88.0/24` - `10.0.90.0/24` (3 × 256 IPs)
- Outgoing Proxy: `10.0.91.0/24` - `10.0.93.0/24` (3 × 256 IPs)
- Utils: `10.0.94.0/24` - `10.0.96.0/24` (3 × 256 IPs)

✅ **No overlaps detected**

### ✅ Each AZ Has Equal Subnets

**AZ-A (eu-central-1a)**: 12 subnets
**AZ-B (eu-central-1b)**: 12 subnets
**AZ-C (eu-central-1c)**: 12 subnets

**Total**: 36 subnets (balanced across 3 AZs)

---

## Deployment Verification

After running `terraform apply`, verify:

### 1. Subnet Count
```bash
terraform output | grep subnet_ids | wc -l
# Expected: 12 (one output per subnet type)
```

### 2. NAT Gateway Count
```bash
terraform output nat_gateway_public_ips
# Expected: 1 IP (dev with single_nat_gateway=true)
# Expected: 3 IPs (prod with single_nat_gateway=false)
```

### 3. VPC CIDR
```bash
terraform output vpc_cidr_block
# Expected: "10.0.0.0/16"
```

### 4. EKS Worker Subnet CIDRs
```bash
terraform output eks_workers_subnet_cidr_blocks
# Expected: [
#   "10.0.32.0/21",
#   "10.0.40.0/21",
#   "10.0.48.0/21"
# ]
```

---

## Quick Reference: Variable to CIDR Mapping

```
external_incoming → 10.0.64.0/22  (64, 65, 66)
management        → 10.0.67.0/22  (67, 68, 69)
eks_control_plane → 10.0.70.0/22  (70, 71, 72)
database          → 10.0.73.0/22  (73, 74, 75)
locker_database   → 10.0.76.0/22  (76, 77, 78)
locker_server     → 10.0.79.0/22  (79, 80, 81)
elasticache       → 10.0.82.0/22  (82, 83, 84)
data_stack        → 10.0.85.0/22  (85, 86, 87)
incoming_envoy    → 10.0.88.0/22  (88, 89, 90)
outgoing_proxy    → 10.0.91.0/22  (91, 92, 93)
utils             → 10.0.94.0/22  (94, 95, 96)

eks_workers       → 10.0.32.0/19  (32-39, 40-47, 48-55)
                    Special: /21 per AZ (2,048 IPs each)
```

---

## Summary

✅ **All files aligned**: terraform.tfvars → variables.tf → main.tf
✅ **12 subnet types**: All properly configured
✅ **No overlaps**: CIDR blocks are non-overlapping
✅ **Balanced AZs**: Equal distribution across 3 AZs
✅ **Security**: Hardcoded security settings
✅ **Clean config**: No old variables remaining
✅ **Ready to deploy**: Configuration validated

**Status**: 🟢 Ready for `terraform apply`
