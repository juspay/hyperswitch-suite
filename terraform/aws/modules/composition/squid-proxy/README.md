# Squid Proxy Composition Module

This module deploys a Squid proxy service with Auto Scaling Group behind a Network Load Balancer.

## Deployment Modes

### Mode 1: Create New NLB (Default)
Creates a new NLB, target group, and ASG.

```hcl
module "squid_proxy" {
  source = "path/to/module"

  create_nlb = true  # Default
  # ... other variables
}
```

### Mode 2: Use Existing NLB
Attach ASG to an existing NLB's listener by creating only a target group and listener rule.

```hcl
module "squid_proxy" {
  source = "path/to/module"

  create_nlb                = false
  existing_lb_arn           = "arn:aws:elasticloadbalancing:..."
  existing_lb_listener_arn  = "arn:aws:elasticloadbalancing:..."
  # Optional: specify priority for listener rule
  listener_rule_priority    = 100

  # ... other variables
}
```

### Mode 3: Use Existing Target Group
Attach ASG to an existing target group (doesn't create anything load balancer related).

```hcl
module "squid_proxy" {
  source = "path/to/module"

  create_nlb          = false
  create_target_group = false
  existing_tg_arn     = "arn:aws:elasticloadbalancing:..."

  # ... other variables
}
```

## Input Variables

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `create_nlb` | bool | No | true | Whether to create a new NLB |
| `create_target_group` | bool | No | true | Whether to create a new target group |
| `existing_lb_arn` | string | Conditional | null | ARN of existing load balancer (required if create_nlb=false) |
| `existing_lb_listener_arn` | string | Conditional | null | ARN of existing listener (required if create_nlb=false) |
| `existing_tg_arn` | string | Conditional | null | ARN of existing target group (required if create_target_group=false) |
| `listener_rule_priority` | number | No | 100 | Priority for listener rule when using existing NLB |

## Examples

See the examples directory for complete usage examples.
