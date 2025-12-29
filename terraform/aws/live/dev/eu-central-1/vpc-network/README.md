# VPC Network - Optimized Configuration

## Overview

This directory contains the **optimized VPC network configuration** based on the [VPC_NETWORK_OPTIMIZED_PLAN.md](../../../../../VPC_NETWORK_OPTIMIZED_PLAN.md) which reduces complexity from 48 subnets to 36 well-designed subnets while properly sizing for 6000+ IPs for EKS workers.

## Changes from Previous Configuration

### Removed (Old Configuration)
- `public_subnet_cidrs` - Replaced with `external_incoming_subnet_cidrs` + `management_subnet_cidrs`
- `private_subnet_cidrs` - Replaced with `eks_workers_subnet_cidrs` (properly sized /21)
- `custom_subnet_groups` - Replaced with dedicated subnet type variables

### Added (New Configuration)
- `external_incoming_subnet_cidrs` - For ALB and NAT Gateways
- `management_subnet_cidrs` - For bastion hosts with Elastic IP
- `eks_workers_subnet_cidrs` - **6,144 IPs** (3x /21 subnets)
- `eks_control_plane_subnet_cidrs` - Isolated EKS control plane
- `locker_database_subnet_cidrs` - PCI-DSS compliant locker database
- `locker_server_subnet_cidrs` - PCI-DSS compliant locker servers
- `data_stack_subnet_cidrs` - For analytics and Kafka
- `incoming_envoy_subnet_cidrs` - For Envoy proxy layer
- `outgoing_proxy_subnet_cidrs` - For Squid proxy
- `utils_subnet_cidrs` - For Lambda and Elasticsearch

## Files in This Directory

### Current Files (To Be Replaced)
- `variables.tf` - **OLD** configuration with fragmented subnets
- `main.tf` - **UPDATED** to use new subnet types
- `outputs.tf` - Unchanged (module outputs handle this)
- `backend.tf` - Unchanged

### New Files
- `variables.optimized.tf` - **NEW** optimized configuration with all CIDR allocations
- `README.optimized.md` - This file

## Migration Steps

### Option 1: Fresh Deployment (Recommended for New Environments)

If this is a **new environment** or you can **recreate the VPC**:

```bash
# 1. Backup current configuration
cp variables.tf variables.tf.backup
cp main.tf main.tf.backup

# 2. Replace with optimized configuration
mv variables.optimized.tf variables.tf

# 3. Review the configuration
cat variables.tf

# 4. Initialize and plan
terraform init
terraform plan

# 5. Deploy
terraform apply
```

### Option 2: In-Place Migration (For Existing VPCs)

If you have an **existing VPC** with resources:

**WARNING**: This will **destroy and recreate subnets**. Any resources in existing subnets will be affected.

```bash
# 1. Create state migration plan
terraform state list | grep subnet

# 2. Backup Terraform state
terraform state pull > terraform.tfstate.backup

# 3. Plan the migration (review carefully!)
terraform plan -out=migration.tfplan

# 4. Review what will be destroyed/created
# Look for:
# - Resources being destroyed (should be old subnets)
# - Resources being created (should be new subnets)
# - Resources being updated (minimal)

# 5. If you have EC2/RDS in subnets, migrate them first!
# DO NOT PROCEED if you have active resources in subnets

# 6. Apply migration
terraform apply migration.tfplan
```

### Option 3: Gradual Migration (Safest for Production)

For **production environments** with active workloads:

1. **Deploy new VPC in parallel**
   ```bash
   # Create new VPC with optimized config
   cd ../vpc-network-new
   terraform init
   terraform apply
   ```

2. **Migrate workloads**
   - Update application configurations to use new subnets
   - Migrate databases (create read replicas in new subnets)
   - Update DNS records
   - Migrate EKS worker nodes (new node groups)

3. **Decommission old VPC**
   - Verify all traffic is on new VPC
   - Remove old resources
   - Destroy old VPC

## Subnet Allocation

See the complete breakdown in [variables.optimized.tf](variables.optimized.tf):

| Subnet Type | CIDR Blocks | IPs per AZ | Total IPs | Purpose |
|-------------|-------------|------------|-----------|---------|
| External Incoming | 10.0.64-66.0/24 | 256 | 768 | ALB, NAT Gateway |
| Management | 10.0.67-69.0/24 | 256 | 768 | Bastion with EIP |
| EKS Workers | 10.0.32/21, 40/21, 48/21 | **2,048** | **6,144** | Main workload |
| EKS Control Plane | 10.0.70-72.0/24 | 256 | 768 | EKS control plane |
| Database | 10.0.73-75.0/24 | 256 | 768 | RDS, Aurora |
| Locker Database | 10.0.76-78.0/24 | 256 | 768 | PCI-DSS DB |
| Locker Server | 10.0.79-81.0/24 | 256 | 768 | PCI-DSS servers |
| ElastiCache | 10.0.82-84.0/24 | 256 | 768 | Redis, Memcached |
| Data Stack | 10.0.85-87.0/24 | 256 | 768 | Kafka, analytics |
| Incoming Envoy | 10.0.88-90.0/24 | 256 | 768 | Envoy proxies |
| Outgoing Proxy | 10.0.91-93.0/24 | 256 | 768 | Squid proxies |
| Utils | 10.0.94-96.0/24 | 256 | 768 | Lambda, ES |
| **Total** | - | - | **13,824** | 21% of VPC |
| **Reserved** | - | - | **51,712** | 79% for expansion |

## Key Features

### Security Improvements
- ✅ **NO automatic public IP assignment** (`map_public_ip_on_launch = false`)
- ✅ **Bastion uses Elastic IP only** (manual assignment)
- ✅ **PCI-DSS compliant locker tier** (fully isolated)
- ✅ **Fully isolated databases** (zero internet access)
- ✅ **NAT Gateway for egress only** (cannot receive inbound)

### Capacity Planning
- ✅ **6,144 IPs for EKS workers** (meets ~6,000 IP requirement)
- ✅ **2,048 IPs per AZ** for worker nodes (using /21 subnets)
- ✅ **51,712 IPs reserved** for future expansion (79% of VPC)
- ✅ **Supports ~13,500 pods** with current allocation

### Cost Optimization
- ✅ **Single NAT Gateway for dev** (`single_nat_gateway = true`)
- ✅ **VPC Endpoints enabled** (reduces NAT data transfer costs)
- ✅ **Right-sized subnets** (no wastage, no fragmentation)

## Configuration Variables

### Required Variables
All variables have defaults in `variables.optimized.tf`. You can override in `terraform.tfvars`:

```hcl
# terraform.tfvars
aws_region = "eu-central-1"
vpc_cidr   = "10.0.0.0/16"

availability_zones = [
  "eu-central-1a",
  "eu-central-1b",
  "eu-central-1c"
]

# For production: High Availability NAT
single_nat_gateway = false  # Creates 3 NAT Gateways (one per AZ)

# For development: Cost Savings
single_nat_gateway = true   # Creates 1 NAT Gateway (shared)

# Enable VPC Flow Logs for production
enable_flow_logs = true
flow_logs_destination_type = "s3"
flow_logs_destination_arn  = "arn:aws:s3:::my-flow-logs-bucket"
```

### Customizing Subnet CIDRs

You can modify any subnet CIDR block in `variables.tf` if needed:

```hcl
variable "eks_workers_subnet_cidrs" {
  default = [
    "10.0.32.0/20",  # Change from /21 to /20 for 4,096 IPs per AZ
    "10.0.48.0/20",
    "10.0.64.0/20"
  ]
}
```

**Important**: Ensure CIDRs don't overlap!

## Testing After Deployment

### 1. Verify VPC and Subnets
```bash
# Check VPC
terraform output vpc_id
terraform output vpc_cidr

# Check subnet counts
terraform output eks_workers_subnet_ids
terraform output external_incoming_subnet_ids
terraform output database_subnet_ids
```

### 2. Verify NAT Gateway
```bash
# Should show 1 or 3 NAT Gateways depending on single_nat_gateway
terraform output nat_gateway_public_ips
```

### 3. Test Bastion Connectivity
```bash
# Allocate Elastic IP
aws ec2 allocate-address --domain vpc

# Launch bastion in management subnet
# Associate Elastic IP to bastion
# SSH to bastion
ssh -i key.pem ec2-user@<elastic-ip>
```

### 4. Test Private Subnet Internet Access
```bash
# From bastion, SSH to an instance in eks-workers subnet
# Test internet access (should work via NAT Gateway)
curl https://google.com  # Should succeed

# From bastion, SSH to an instance in database subnet
# Test internet access (should FAIL - no route)
curl https://google.com  # Should fail - no internet
```

### 5. Verify VPC Endpoints
```bash
# Check VPC endpoints created
terraform output gateway_vpc_endpoint_ids
terraform output interface_vpc_endpoint_ids

# Test S3 access via VPC endpoint (not NAT Gateway)
aws s3 ls --region eu-central-1
```

## Outputs

The module exports comprehensive outputs:

```hcl
# VPC
module.vpc_network.vpc_id
module.vpc_network.vpc_cidr_block

# Subnets (all types)
module.vpc_network.external_incoming_subnet_ids
module.vpc_network.management_subnet_ids
module.vpc_network.eks_workers_subnet_ids
module.vpc_network.eks_control_plane_subnet_ids
module.vpc_network.database_subnet_ids
module.vpc_network.locker_database_subnet_ids
module.vpc_network.locker_server_subnet_ids
module.vpc_network.elasticache_subnet_ids
module.vpc_network.data_stack_subnet_ids
module.vpc_network.incoming_envoy_subnet_ids
module.vpc_network.outgoing_proxy_subnet_ids
module.vpc_network.utils_subnet_ids

# NAT Gateways
module.vpc_network.nat_gateway_ids
module.vpc_network.nat_gateway_public_ips

# VPC Endpoints
module.vpc_network.gateway_vpc_endpoint_ids
module.vpc_network.interface_vpc_endpoint_ids
```

## Troubleshooting

### Issue: Terraform shows many resources will be destroyed

**Cause**: You're migrating from old subnet structure to new one.

**Solution**: This is expected. Review carefully:
- Old subnets will be destroyed (e.g., `module.public_subnets`)
- New subnets will be created (e.g., `module.external_incoming_subnets`)
- **Ensure no EC2/RDS instances in old subnets before applying!**

### Issue: `map_public_ip_on_launch` error

**Cause**: You may have old variable references.

**Solution**: Ensure you're using the new `variables.optimized.tf` which sets this to `false` by default.

### Issue: EKS workers can't pull images

**Cause**: VPC endpoints not configured or NAT Gateway issue.

**Solution**:
1. Verify VPC endpoints for ECR are created:
   ```bash
   terraform output interface_vpc_endpoint_ids | grep ecr
   ```
2. Check NAT Gateway is working:
   ```bash
   terraform output nat_gateway_public_ips
   ```
3. Verify route tables have NAT routes:
   ```bash
   terraform output eks_workers_route_table_ids
   ```

### Issue: Database can't connect

**Cause**: Databases in isolated subnets (by design - security feature).

**Solution**: This is correct! Access databases from:
- EKS worker subnets
- Application subnets
- Via VPC peering/Transit Gateway

Never directly from internet - that's the point of isolation.

## Cost Estimate

### Development Environment
- **NAT Gateway**: 1x = $35/month
- **Data Transfer**: ~$20-50/month
- **VPC Endpoints**: 4x = $30/month
- **Total**: ~$90-120/month

### Production Environment
- **NAT Gateways**: 3x = $105/month
- **Data Transfer**: ~$100-500/month (reduced with endpoints)
- **VPC Endpoints**: 10x = $75/month
- **Total**: ~$300-730/month

## Security Best Practices

### Implemented
- ✅ No auto-assigned public IPs
- ✅ Bastion uses Elastic IP
- ✅ Databases fully isolated
- ✅ PCI-DSS compliant locker tier
- ✅ VPC endpoints for AWS services
- ✅ Network ACLs configured

### Recommended Next Steps
1. **Enable VPC Flow Logs** (production)
   ```hcl
   enable_flow_logs = true
   flow_logs_destination_type = "s3"
   ```

2. **Configure Security Groups** (not in this module)
   - Least privilege access
   - Port-specific rules
   - Source-based restrictions

3. **Enable AWS WAF** on ALBs
   - OWASP Top 10 protection
   - Rate limiting
   - Geo-blocking if needed

4. **Set up CloudWatch Alarms**
   - NAT Gateway metrics
   - Subnet IP utilization
   - VPC Flow Log analysis

## Support and Documentation

- **Full Plan**: [VPC_NETWORK_OPTIMIZED_PLAN.md](../../../../../VPC_NETWORK_OPTIMIZED_PLAN.md)
- **Module Source**: [terraform/aws/modules/composition/vpc-network/](../../../../modules/composition/vpc-network/)
- **AWS VPC Docs**: https://docs.aws.amazon.com/vpc/

## Summary

This optimized configuration provides:
- ✅ **36 subnets** (down from 48)
- ✅ **6,144 IPs for EKS** (meets 6,000 IP requirement)
- ✅ **No public IPs** (except bastion with Elastic IP)
- ✅ **PCI-DSS ready** (isolated locker tier)
- ✅ **Cost optimized** (VPC endpoints, right-sizing)
- ✅ **Production ready** (HA options, security features)

Deploy to dev first, test thoroughly, then roll out to production!
