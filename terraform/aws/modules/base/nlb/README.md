# Network Load Balancer (NLB) Base Module

## Overview

This is a reusable base module for creating AWS Network Load Balancers. It provides a standardized way to create NLBs across different environments and compositions.

## Features

- Network Load Balancer (Layer 4 - TCP/UDP)
- Internal or external configuration
- Configurable security groups
- Access logs configuration
- Cross-zone load balancing
- Deletion protection for production environments

## Usage

```hcl
module "nlb" {
  source = "../../base/nlb"

  name               = "my-application-nlb"
  internal           = true
  subnets            = ["subnet-abc123", "subnet-def456"]
  security_groups    = ["sg-abc123"]

  enable_deletion_protection       = true
  enable_cross_zone_load_balancing = true

  tags = {
    Environment = "prod"
    Project     = "myapp"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the network load balancer | string | - | yes |
| internal | Whether the load balancer is internal or external | bool | true | no |
| subnets | List of subnet IDs to attach to the load balancer | list(string) | - | yes |
| security_groups | List of security group IDs to attach to the load balancer | list(string) | [] | no |
| enable_deletion_protection | Enable deletion protection on the load balancer | bool | false | no |
| enable_cross_zone_load_balancing | Enable cross-zone load balancing | bool | true | no |
| access_logs | Access logs configuration | object | {enabled=false} | no |
| tags | Map of tags to apply to the load balancer | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| nlb_id | ID of the network load balancer |
| nlb_arn | ARN of the network load balancer |
| nlb_arn_suffix | ARN suffix for use with CloudWatch Metrics |
| nlb_dns_name | DNS name of the network load balancer |
| nlb_zone_id | Canonical hosted zone ID of the network load balancer |
| nlb_name | Name of the network load balancer |

## Access Logs Configuration

To enable access logs:

```hcl
module "nlb" {
  source = "../../base/nlb"

  name = "my-nlb"
  # ... other configuration ...

  access_logs = {
    enabled = true
    bucket  = "my-nlb-logs-bucket"
    prefix  = "nlb-logs"
  }
}
```

## NLB vs ALB

### When to use NLB (this module):
- Need Layer 4 (TCP/UDP) load balancing
- Require ultra-low latency
- Need static IP addresses
- Handle millions of requests per second
- Use cases: Databases, gaming servers, IoT, proxy services

### When to use ALB:
- Need Layer 7 (HTTP/HTTPS) load balancing
- Require path-based or host-based routing
- Need WebSocket support
- SSL/TLS termination at load balancer
- Use cases: Web applications, microservices, APIs

## Notes

- NLB operates at Layer 4 (TCP/UDP) - does not inspect HTTP headers
- Security groups are optional for NLB (can use NACLs instead)
- The module includes lifecycle management with create_before_destroy
- NLB supports preserving client IP addresses by default
- Cross-zone load balancing is enabled by default for even distribution
