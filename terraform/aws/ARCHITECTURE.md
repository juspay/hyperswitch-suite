# Terraform Architecture Documentation

Production-ready Terraform infrastructure for Hyperswitch proxy services with modular, three-layer architecture.

## Module Architecture

### Layer 1: Base Modules (`modules/base/`)

Atomic AWS resource wrappers - reusable building blocks:
- `asg/` - Auto Scaling Group with health checks and instance refresh
- `security-group/` - Dynamic ingress/egress rules with CIDR and SG support
- `s3-bucket/` - Encryption, versioning, lifecycle policies
- `iam-role/` - IAM roles with managed and inline policies
- `target-group/` - Load balancer target groups with health checks
- `launch-template/` - EC2 launch configurations

### Layer 2: Composition Modules (`modules/composition/`)

Service orchestration combining base modules:

**squid-proxy/**
- Components: NLB + ASG + S3 (config/logs) + Security Groups + IAM
- Features: Domain whitelisting, S3 config templating, EKS CIDR support, instance refresh
- Purpose: Outbound HTTP/HTTPS proxy with domain filtering

**envoy-proxy/**
- Components: ALB + ASG + S3 (config/logs) + Security Groups + IAM
- Features: Envoy.yaml templating, SSL termination, advanced routing, instance refresh
- Purpose: Ingress proxy for CloudFront traffic

### Layer 3: Live Deployments (`live/`)

Environment-specific configurations:
- `dev/` - Public reference with masked values, local state
- `integ/` - Integration/UAT, remote state (S3 + DynamoDB)
- `prod/` - Production, encrypted remote state (S3 + DynamoDB + KMS)
- `sandbox/` - Experimentation, ephemeral resources

## System Architecture

### Squid Proxy Flow

```
EKS Pod (10.0.10.180)
  ↓ HTTP_PROXY=http://nlb:80
Network Load Balancer (TCP/80 → 3128)
  ↓ Preserves source IP
Squid ASG (port 3128)
  ↓ Checks whitelist.txt
Internet (whitelisted domains only)
```

**Key Points:**
- NLB preserves source IP, requires CIDR-based security group rules
- TCP listener on port 80, forwards to Squid on port 3128
- Domain whitelist enforced from `config/whitelist.txt`
- Multi-AZ deployment for high availability

### Envoy Proxy Flow

```
CloudFront
  ↓
External ALB (HTTP/HTTPS)
  ↓ SSL termination
Envoy ASG (ports 80, 9901)
  ↓ Advanced routing
Internal ALB
  ↓
EKS Cluster
```

**Key Points:**
- ALB handles SSL termination
- Envoy.yaml templating for CloudFront DNS and Internal ALB DNS
- Header-based and path-based routing

## Security Architecture

### Network Security

**Squid ASG Security Group:**
```
Inbound:
- TCP 3128 from EKS worker subnet CIDRs (10.0.8.0/22, 10.0.12.0/22)
- TCP 3128 from NLB subnet CIDRs (10.0.30.0/24, 10.0.31.0/24) for health checks

Outbound:
- TCP 80, 443 to 0.0.0.0/0 (internet access)
```

**Why CIDR Rules?**
NLB preserves client source IP. Traffic from pod (10.0.10.180) appears with pod IP at Squid instance. Security group references alone don't work - must explicitly allow EKS worker subnet CIDRs.

### IAM Security

```
Instance Profile → IAM Role
  ├─ Managed Policies: SSM access, CloudWatch logs/metrics
  └─ Inline Policies:
     - S3 Config Bucket: s3:GetObject (read-only)
     - S3 Logs Bucket: s3:PutObject (write-only)
```

Least privilege: scoped to specific bucket ARNs only.

### Data Encryption

- S3: AES256 encryption at rest, versioning enabled, public access blocked
- Terraform State: S3 backend with encryption, DynamoDB locking
- Transit: Internal VPC traffic unencrypted, HTTPS to internet

## Configuration Management

### Instance Refresh (Zero Downtime)

```
1. Update config files or terraform.tfvars
2. terraform apply updates launch template
3. ASG starts instance refresh
4. Checkpoint at 50% (5 min wait for validation)
5. Auto-continues or manual cancel
6. All instances replaced with zero downtime
```

### Config Upload Flow

```
Local files (config/squid.conf, whitelist.txt)
  ↓ terraform apply
S3 Config Bucket (MD5 tracking)
  ↓ Instance launch/refresh
User Data Script downloads from S3
  ↓ Apply and restart service
Instance becomes healthy
```

## State Management

### Structure

```
S3: hyperswitch-terraform-state-{env}
├── {env}/{region}/squid-proxy/terraform.tfstate
└── {env}/{region}/envoy-proxy/terraform.tfstate

DynamoDB: terraform-state-lock-{env}
```

Benefits: Isolated state per service, parallel development, limited blast radius.

### Remote Backend

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

## Environment Configuration

| Environment | Instance Type | Capacity | Monitoring | State Backend | Use Case |
|-------------|---------------|----------|------------|---------------|----------|
| dev | t3.small | 1 (min:1, max:2) | Basic | Local | Testing, reference |
| integ | t3.medium | 1-2 (min:1, max:3) | Detailed | S3+DynamoDB | Integration, UAT |
| prod | t3.medium+ | 2+ (min:2, max:6) | Detailed | S3+DynamoDB+KMS | Production workloads |
| sandbox | t3.micro | 0-1 (min:0, max:2) | Basic | Local/S3 | Experimentation |

## Monitoring

### Key Metrics

**ASG:** DesiredCapacity, InServiceInstances, health status

**EC2:** CPUUtilization, NetworkIn/Out, StatusCheckFailed

**NLB:** HealthyHostCount, ActiveConnectionCount, TargetResponseTime

**ALB:** RequestCount, HTTPCode_Target_2XX/4XX/5XX, TargetResponseTime

### Logging

- Application logs (Squid/Envoy access logs) → S3 with lifecycle policies
- System logs → CloudWatch Logs
- Retention: 90 days (prod), 30 days (dev/integ)

## Disaster Recovery

### Recovery Scenarios

| Scenario | Detection | Recovery | RTO |
|----------|-----------|----------|-----|
| Instance failure | CloudWatch (1-2 min) | ASG auto-replace (3-5 min) | 6 min |
| AZ failure | Health checks (2 min) | ASG launch in healthy AZ (5-10 min) | 12 min |
| Config rollback | Manual | S3 version revert + instance refresh | 10 min |
| Complete ASG failure | Manual (3 min) | terraform apply (10-15 min) | 18 min |

### Backup Strategy

- Terraform state: S3 versioning enabled, 30-day retention
- Config files: S3 versioning, 90-day retention
- Logs: Lifecycle policies, Intelligent Tiering

## Cost Optimization

### Instance Costs (eu-central-1)

| Instance | vCPU | Memory | Cost/Hour | Monthly (1 instance) |
|----------|------|--------|-----------|---------------------|
| t3.micro | 2 | 1 GB | $0.0104 | ~$7.50 |
| t3.small | 2 | 2 GB | $0.0208 | ~$15 |
| t3.medium | 2 | 4 GB | $0.0416 | ~$30 |
| t3.large | 2 | 8 GB | $0.0832 | ~$60 |

Additional: NLB $0.0225/hour + data transfer costs

### Strategies

- **Dev/Sandbox:** Scale down during off-hours, minimal monitoring
- **Prod:** Reserved Instances (30-50% savings), S3 Intelligent Tiering
- **All:** Right-size based on metrics, lifecycle policies for logs

## Architecture Benefits

- **Modularity:** Reusable components, update once apply everywhere
- **Security:** Least privilege IAM, encryption, network isolation
- **Reliability:** Multi-AZ, health checks, auto-recovery
- **Scalability:** ASG-based, handles demand spikes
- **Zero Downtime:** Instance refresh with checkpoints
- **Cost Efficiency:** Right-sized resources, lifecycle policies
- **Isolation:** Separate state per deployment (blast radius control)
