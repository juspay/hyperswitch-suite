# Production Environment - EU Central 1

This directory will contain production deployments for the eu-central-1 region.

## Structure

```
prod/eu-central-1/
├── squid-proxy/       # TODO: Create configuration
├── envoy-proxy/       # TODO: Create configuration
├── vpc/               # TODO: Create VPC first
└── eks-cluster/       # TODO: Create EKS cluster
```

## Important Notes

- Production uses **S3 backend** with state locking
- **Deletion protection** is enabled for critical resources
- Requires **manual approval** for apply operations
- Use larger instance types and higher ASG minimums for HA
- Detailed monitoring is **enabled** by default

## Prerequisites

1. Create VPC infrastructure first
2. Set up S3 backend bucket
3. Create DynamoDB table for state locking
4. Configure AWS credentials with appropriate IAM permissions

## Deployment Order

1. VPC
2. Shared resources (Load Balancers, etc.)
3. Squid Proxy
4. Envoy Proxy
5. EKS Cluster
