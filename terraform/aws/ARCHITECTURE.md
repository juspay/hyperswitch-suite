# Architecture Documentation

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          AWS Cloud (eu-central-1)                        │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                            VPC                                   │   │
│  │                                                                  │   │
│  │  ┌──────────────────────────┐  ┌──────────────────────────┐   │   │
│  │  │  Service Layer Subnets   │  │  Proxy Layer Subnets     │   │   │
│  │  │                          │  │                          │   │   │
│  │  │  ┌────────────────┐     │  │  ┌────────────────┐     │   │   │
│  │  │  │ Squid NLB      │     │  │  │ Squid ASG      │     │   │   │
│  │  │  │                │─────┼──┼─▶│                │     │   │   │
│  │  │  │ Port: 3128     │     │  │  │ t3.small       │     │   │   │
│  │  │  └────────────────┘     │  │  │ Min: 1 Max: 2  │     │   │   │
│  │  │         │               │  │  └────────────────┘     │   │   │
│  │  │         │               │  │         │               │   │   │
│  │  │  ┌────────────────┐     │  │         │ NAT Gateway   │   │   │
│  │  │  │ Envoy NLB      │     │  │         ▼               │   │   │
│  │  │  │                │─────┼──┼──▶ Internet           │   │   │
│  │  │  │ Port: 10000    │     │  │                         │   │   │
│  │  │  └────────────────┘     │  │  ┌────────────────┐     │   │   │
│  │  │         │               │  │  │ Envoy ASG      │     │   │   │
│  │  │         └───────────────┼──┼─▶│                │     │   │   │
│  │  │                         │  │  │ t3.small       │     │   │   │
│  │  │  ┌────────────────┐     │  │  │ Min: 1 Max: 2  │     │   │   │
│  │  │  │ EKS Cluster    │     │  │  └────────────────┘     │   │   │
│  │  │  │                │     │  │                          │   │   │
│  │  │  │ ┌────┐ ┌────┐ │     │  │                          │   │   │
│  │  │  │ │Pod │ │Pod │ │     │  │                          │   │   │
│  │  │  │ └─┬──┘ └──┬─┘ │     │  │                          │   │   │
│  │  │  │   │       │   │     │  │                          │   │   │
│  │  │  │   └───┬───┘   │     │  │                          │   │   │
│  │  │  └───────┼───────┘     │  │                          │   │   │
│  │  │          │             │  │                          │   │   │
│  │  └──────────┼─────────────┘  └──────────────────────────┘   │   │
│  │             │                                                 │   │
│  └─────────────┼─────────────────────────────────────────────────┘   │
│                │                                                       │
│                └──▶ HTTP(S) Proxy Traffic                            │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                      Supporting Services                      │   │
│  │                                                               │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │   │
│  │  │ S3: Configs  │  │ S3: Squid    │  │ S3: Envoy    │      │   │
│  │  │              │  │    Logs      │  │    Logs      │      │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘      │   │
│  │                                                               │   │
│  │  ┌──────────────┐  ┌──────────────┐                         │   │
│  │  │ CloudWatch   │  │ IAM Roles    │                         │   │
│  │  │ Metrics/Logs │  │ & Policies   │                         │   │
│  │  └──────────────┘  └──────────────┘                         │   │
│  └──────────────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────────────┘
```

## Module Dependency Graph

```
┌────────────────────────────────────────────────────────────────┐
│                     Base Modules (Atomic)                       │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐       │
│  │    ASG      │  │ Target Group │  │Security Group  │       │
│  └─────────────┘  └──────────────┘  └────────────────┘       │
│                                                                 │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐       │
│  │  IAM Role   │  │  S3 Bucket   │  │Launch Template │       │
│  └─────────────┘  └──────────────┘  └────────────────┘       │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
                           │
                           │ Used by
                           ▼
┌────────────────────────────────────────────────────────────────┐
│               Composition Modules (Orchestration)               │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────┐     │
│  │              Squid Proxy Module                      │     │
│  │                                                       │     │
│  │  • Uses: ASG + Target Group + SG + IAM + S3 + LT    │     │
│  │  • Creates: NLB, Listener, Userdata                  │     │
│  │  • Outputs: NLB DNS, ASG Name, Bucket ARN           │     │
│  └──────────────────────────────────────────────────────┘     │
│                                                                 │
│  ┌──────────────────────────────────────────────────────┐     │
│  │              Envoy Proxy Module                      │     │
│  │                                                       │     │
│  │  • Uses: ASG + Target Group + SG + IAM + S3 + LT    │     │
│  │  • Creates: NLB, Listener, Userdata                  │     │
│  │  • Outputs: NLB DNS, ASG Name, Bucket ARN           │     │
│  └──────────────────────────────────────────────────────┘     │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
                           │
                           │ Deployed by
                           ▼
┌────────────────────────────────────────────────────────────────┐
│                  Live Deployments (Root Modules)                │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  dev/eu-central-1/squid-proxy/     ← Local Backend            │
│  dev/eu-central-1/envoy-proxy/     ← Local Backend            │
│                                                                 │
│  integ/eu-central-1/squid-proxy/   ← S3 Backend               │
│  integ/eu-central-1/envoy-proxy/   ← S3 Backend               │
│                                                                 │
│  prod/eu-central-1/squid-proxy/    ← S3 Backend (TODO)        │
│  prod/eu-central-1/envoy-proxy/    ← S3 Backend (TODO)        │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Request Flow (Squid Proxy)

```
┌──────┐      ┌──────────┐      ┌──────────┐      ┌──────────┐
│ EKS  │─────▶│ Squid    │─────▶│ Target   │─────▶│  Squid   │
│ Pod  │      │   NLB    │      │  Group   │      │ Instance │
└──────┘      └──────────┘      └──────────┘      └──────────┘
                                                         │
                                                         ▼
                                                   ┌──────────┐
                                                   │ Internet │
                                                   └──────────┘
```

### Configuration Flow

```
┌──────────┐      ┌──────────┐      ┌──────────┐
│ S3 Config│─────▶│ Instance │─────▶│  Squid/  │
│  Bucket  │      │ Userdata │      │  Envoy   │
└──────────┘      └──────────┘      └──────────┘
                       │
                       ▼
                  ┌──────────┐
                  │ Downloads│
                  │  Config  │
                  └──────────┘
```

### Logging Flow

```
┌──────────┐      ┌──────────┐      ┌──────────┐
│  Squid/  │─────▶│   S3     │      │CloudWatch│
│  Envoy   │      │  Logs    │      │   Logs   │
│ Instance │      │  Bucket  │      └──────────┘
└──────────┘      └──────────┘            ▲
                       │                   │
                       └───────────────────┘
                        (Both destinations)
```

## State File Architecture

```
S3: hyperswitch-terraform-state
│
├── dev/
│   └── eu-central-1/
│       ├── squid-proxy/terraform.tfstate   (Isolated)
│       └── envoy-proxy/terraform.tfstate   (Isolated)
│
├── integ/
│   └── eu-central-1/
│       ├── squid-proxy/terraform.tfstate   (Isolated)
│       └── envoy-proxy/terraform.tfstate   (Isolated)
│
└── prod/
    └── eu-central-1/
        ├── squid-proxy/terraform.tfstate   (Isolated)
        └── envoy-proxy/terraform.tfstate   (Isolated)

Benefits:
✓ Each deployment has separate state
✓ Blast radius contained
✓ Teams can work in parallel
✓ No state conflicts
```

## Security Architecture

### Network Security

```
┌─────────────────────────────────────────────────────┐
│                  Security Groups                     │
├─────────────────────────────────────────────────────┤
│                                                      │
│  EKS SG ────▶ NLB SG ────▶ ASG SG ────▶ Internet   │
│                                                      │
│  Ingress Rules:                                     │
│  • NLB SG: Port 3128 from EKS SG                   │
│  • ASG SG: Port 3128 from NLB SG                   │
│                                                      │
│  Egress Rules:                                      │
│  • ASG SG: Port 80/443 to 0.0.0.0/0                │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### IAM Security

```
┌─────────────────────────────────────────────────────┐
│                    IAM Structure                     │
├─────────────────────────────────────────────────────┤
│                                                      │
│  Instance Profile                                   │
│       │                                             │
│       ├─▶ IAM Role                                  │
│           │                                         │
│           ├─▶ Managed Policies:                    │
│           │   • AmazonSSMManagedInstanceCore       │
│           │   • CloudWatchAgentServerPolicy        │
│           │                                         │
│           └─▶ Inline Policies:                     │
│               • S3 Config Read (GetObject)         │
│               • S3 Logs Write (PutObject)          │
│                                                      │
└─────────────────────────────────────────────────────┘
```

## Deployment Strategy

### Environment Progression

```
┌─────────┐      ┌─────────┐      ┌─────────┐
│   DEV   │─────▶│  INTEG  │─────▶│  PROD   │
└─────────┘      └─────────┘      └─────────┘
    │                │                 │
    │                │                 │
Local Backend    S3 Backend      S3 Backend
Small Instances  Medium Inst.    Large Inst.
Min: 1           Min: 1          Min: 2
No Monitoring    Monitoring      Full Monitor
Fast Iteration   Integration     Stable/HA
```

### Change Management

```
1. Develop in feature branch
2. Test in dev environment
3. Create PR for review
4. Deploy to integ for integration testing
5. After approval, deploy to prod
6. Monitor and rollback if needed
```

## Scaling Architecture

### Auto Scaling Configuration

```
Environment │ Min │ Max │ Desired │ Scale Up │ Scale Down
────────────┼─────┼─────┼─────────┼──────────┼───────────
dev         │  1  │  2  │    1    │ CPU>70%  │ CPU<30%
integ       │  1  │  3  │    2    │ CPU>70%  │ CPU<30%
prod        │  2  │  6  │    2    │ CPU>60%  │ CPU<40%
```

### Cost Optimization

```
┌──────────────────────────────────────────────────┐
│            Cost Optimization Strategy             │
├──────────────────────────────────────────────────┤
│                                                   │
│  Dev:                                            │
│  • Instance: t3.small ($0.0208/hr)              │
│  • ASG: 1 instance                               │
│  • Cost: ~$15/month                              │
│                                                   │
│  Integ:                                          │
│  • Instance: t3.medium ($0.0416/hr)             │
│  • ASG: 2 instances                              │
│  • Cost: ~$60/month                              │
│                                                   │
│  Prod:                                           │
│  • Instance: t3.large ($0.0832/hr)              │
│  • ASG: 2-6 instances (avg 2)                   │
│  • Reserved Instances: 30% savings               │
│  • Cost: ~$115/month                             │
│                                                   │
└──────────────────────────────────────────────────┘
```

## Disaster Recovery

### Backup Strategy

```
┌──────────────────────────────────────────────────┐
│              Backup & Recovery                    │
├──────────────────────────────────────────────────┤
│                                                   │
│  Terraform State:                                │
│  • S3 versioning enabled                         │
│  • 30-day version retention                      │
│  • Cross-region replication (optional)           │
│                                                   │
│  Configuration Files:                            │
│  • Stored in S3 config bucket                    │
│  • Versioning enabled                            │
│  • Lifecycle: 90 days                            │
│                                                   │
│  Logs:                                           │
│  • S3 logs bucket                                │
│  • Intelligent Tiering                           │
│  • 90-day retention (prod)                       │
│  • 30-day retention (dev/integ)                  │
│                                                   │
└──────────────────────────────────────────────────┘
```

### Recovery Time Objective (RTO)

```
Failure Scenario      │ Detection │ Recovery │ Total RTO
──────────────────────┼───────────┼──────────┼──────────
Instance Failure      │  1 min    │  5 min   │  6 min
AZ Failure           │  2 min    │  10 min  │  12 min
Complete ASG Loss    │  3 min    │  15 min  │  18 min
Region Failure       │  5 min    │  60 min  │  65 min
```

## Monitoring & Observability

### Metrics Collected

```
┌──────────────────────────────────────────────────┐
│              CloudWatch Metrics                   │
├──────────────────────────────────────────────────┤
│                                                   │
│  ASG Metrics:                                    │
│  • GroupMinSize, GroupMaxSize                    │
│  • GroupDesiredCapacity                          │
│  • GroupInServiceInstances                       │
│                                                   │
│  Instance Metrics:                               │
│  • CPUUtilization                                │
│  • NetworkIn/NetworkOut                          │
│  • MemoryUtilization (custom)                    │
│                                                   │
│  NLB Metrics:                                    │
│  • ActiveConnectionCount                         │
│  • ProcessedBytes                                │
│  • HealthyHostCount                              │
│                                                   │
│  Custom Metrics:                                 │
│  • Squid: Request Rate, Cache Hit Ratio         │
│  • Envoy: Connection Count, Latency             │
│                                                   │
└──────────────────────────────────────────────────┘
```

## Summary

This architecture provides:

✅ **Modularity**: Base modules reused across services
✅ **Isolation**: Separate state files per deployment
✅ **Scalability**: Auto Scaling based on demand
✅ **Security**: Least privilege IAM, encrypted data
✅ **Observability**: Comprehensive logging and monitoring
✅ **Cost-Effective**: Right-sized instances per environment
✅ **Disaster Recovery**: Backups and quick recovery
✅ **Multi-Environment**: Dev, Integ, Prod support
