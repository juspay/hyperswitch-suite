# NLB Listener Base Module

## Overview

This is a reusable base module for creating AWS Network Load Balancer Listeners. It provides a standardized way to configure NLB listeners for TCP, TLS, UDP, and TCP_UDP protocols.

## Features

- Support for TCP, TLS, UDP, TCP_UDP protocols
- Forward to target groups
- SSL/TLS certificate management for TLS listeners
- Configurable SSL policies
- ALPN policy support

## Usage

### TCP Listener (Most Common for Proxies)

```hcl
module "tcp_listener" {
  source = "../../base/nlb-listener"

  name                = "squid-proxy-tcp"
  load_balancer_arn   = module.nlb.nlb_arn
  port                = 3128
  protocol            = "TCP"
  target_group_arn    = module.target_group.tg_arn

  tags = {
    Environment = "prod"
  }
}
```

### TLS Listener with Certificate

```hcl
module "tls_listener" {
  source = "../../base/nlb-listener"

  name                = "secure-proxy-tls"
  load_balancer_arn   = module.nlb.nlb_arn
  port                = 443
  protocol            = "TLS"
  certificate_arn     = "arn:aws:acm:region:account:certificate/abc123"
  ssl_policy          = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  target_group_arn    = module.target_group.tg_arn

  tags = {
    Environment = "prod"
  }
}
```

### UDP Listener

```hcl
module "udp_listener" {
  source = "../../base/nlb-listener"

  name                = "dns-proxy-udp"
  load_balancer_arn   = module.nlb.nlb_arn
  port                = 53
  protocol            = "UDP"
  target_group_arn    = module.target_group.tg_arn

  tags = {
    Environment = "prod"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name identifier for the listener (used in tags) | string | - | yes |
| load_balancer_arn | ARN of the network load balancer | string | - | yes |
| port | Port on which the load balancer is listening | number | - | yes |
| protocol | Protocol for connections from clients to the load balancer | string | "TCP" | no |
| ssl_policy | Name of the SSL Policy for the listener (required for TLS) | string | "ELBSecurityPolicy-TLS13-1-2-2021-06" | no |
| certificate_arn | ARN of the default SSL server certificate (required for TLS) | string | null | no |
| alpn_policy | Name of the Application-Layer Protocol Negotiation (ALPN) policy | string | null | no |
| target_group_arn | ARN of the target group to forward traffic to | string | - | yes |
| tags | Map of tags to apply to the listener | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| listener_id | ID of the listener |
| listener_arn | ARN of the listener |
| listener_port | Port of the listener |
| listener_protocol | Protocol of the listener |

## Protocol Details

### TCP (Default)
- Layer 4 load balancing
- No SSL/TLS termination at load balancer
- Preserves client IP
- Best for: Proxies, databases, generic TCP services

### TLS
- TCP with SSL/TLS termination at load balancer
- Requires certificate_arn
- Offloads SSL/TLS from backend
- Best for: Secure proxies, encrypted connections

### UDP
- Connectionless protocol
- Best for: DNS, gaming, streaming, VoIP

### TCP_UDP
- Listens on both TCP and UDP
- Single listener for dual-protocol services
- Best for: Services that use both protocols

## SSL/TLS Best Practices

### Recommended SSL Policies for TLS Listeners

- **Modern (TLS 1.3)**: `ELBSecurityPolicy-TLS13-1-2-2021-06`
- **Backward Compatible (TLS 1.2+)**: `ELBSecurityPolicy-TLS-1-2-2017-01`
- **FS Only**: `ELBSecurityPolicy-FS-1-2-2019-08`

### Certificate Management

1. Use AWS Certificate Manager (ACM) for SSL/TLS certificates
2. Enable automatic renewal for ACM certificates
3. For TLS listeners, always specify `certificate_arn`

## NLB Listener Limitations

Unlike ALB listeners, NLB listeners:
- **Do NOT support listener rules** with path/host-based routing
- Only support a single default action (forward to target group)
- Cannot perform redirects or return fixed responses
- Operate at Layer 4, not Layer 7

## Port Validation

The module validates that the port is between 1 and 65535.

## Protocol Validation

Supported protocols:
- TCP
- TLS
- UDP
- TCP_UDP

## Examples in Squid Proxy Module

The squid-proxy composition module uses this base module internally. See:
- `terraform/aws/modules/composition/squid-proxy/main.tf` (lines 322-335)

## Notes

- For TLS listeners, `certificate_arn` is required
- The module only supports forward action (NLB limitation)
- No listener rules support (use ALB for advanced routing)
- Protocol validation ensures only valid NLB protocols are used
