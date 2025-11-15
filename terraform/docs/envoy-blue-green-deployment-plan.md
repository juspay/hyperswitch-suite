# Envoy Proxy Blue-Green Deployment Plan

## Overview
Implement a robust blue-green deployment system with gradual canary traffic shifting (1→5→10→25→50→100%) for the Envoy proxy ASG, orchestrated by Argo Workflows executing bash scripts, with comprehensive validation and 1-hour rollback window.

## Current Architecture Summary

### Existing Setup
- **ASG Configuration**: Single ASG with instance refresh enabled
  - Min: 1, Max: 2, Desired: 1
  - Health check: ELB with 300s grace period
  - Instance refresh with 50% min healthy percentage
- **Load Balancer**: Application Load Balancer (ALB)
  - Single target group (HTTP port 80)
  - Health check: `/healthz` endpoint, 30s interval
  - Deregistration delay: 30 seconds
- **Deployment Method**: Instance refresh via null_resource trigger
  - Triggered by envoy.yaml config changes (MD5 hash)
  - Checkpoint at 50% with manual continuation

### Current Limitations
- Rolling replacement (not true blue-green)
- No traffic weighting capability
- Single target group only
- Manual checkpoint intervention required
- No automated validation or rollback

## Proposed Architecture

### Design Decisions
- **Orchestration**: Argo Workflows + Bash scripts (best of both worlds)
- **Traffic Strategy**: Gradual canary (1→5→10→25→50→100%)
- **Validation**: Multi-layered
  - ALB health checks
  - CloudWatch alarms (error rates, latency)
  - Custom health endpoint validation
  - Manual approval gates (at key percentages)
- **Wait Time**: 5 minutes between each traffic shift
- **Rollback Window**: 1 hour (old ASG kept at zero capacity)
- **Cleanup**: Automatic after rollback window expires

### Key Components

#### 1. Blue-Green ASG Architecture
```
┌─────────────────────────────────────────┐
│         Application Load Balancer        │
│                                          │
│  Listener (Port 80/443)                 │
│    ├─ Blue Target Group (Weight: 0-100%)│
│    └─ Green Target Group (Weight: 0-100%)│
└─────────────────────────────────────────┘
           │                    │
           │                    │
    ┌──────▼──────┐      ┌─────▼───────┐
    │   Blue ASG   │      │  Green ASG  │
    │  (Current)   │      │   (New)     │
    │              │      │             │
    │ t3.small ×N  │      │ t3.small ×N │
    └──────────────┘      └─────────────┘
```

#### 2. Traffic Shift Progression
```
Step 1: Blue 99% | Green  1%  (5 min wait + validation)
Step 2: Blue 95% | Green  5%  (5 min wait + validation)
Step 3: Blue 90% | Green 10%  (5 min wait + validation)
Step 4: Blue 75% | Green 25%  (5 min wait + validation)
Step 5: Blue 50% | Green 50%  (5 min wait + MANUAL APPROVAL + validation)
Step 6: Blue  0% | Green 100% (Final validation)
Step 7: Scale Blue ASG to 0 (keep for 1-hour rollback window)
Step 8: Delete Blue ASG (after 1 hour)
```

## Implementation Plan

### Phase 1: Terraform Module Enhancements

#### 1.1 Update Envoy-Proxy Composition Module
**File**: `aws/modules/composition/envoy-proxy/main.tf`

**Changes**:
- Add conditional logic for blue/green ASG creation
- Create two target groups (blue-tg, green-tg)
- Modify ALB listener to support weighted target groups
- Add data source to detect current active deployment color
- Update naming convention: `${var.name}-${var.deployment_color}`

**New Resources**:
```hcl
# Dual target groups
resource "aws_lb_target_group" "blue" { ... }
resource "aws_lb_target_group" "green" { ... }

# Conditional ASG based on deployment_color variable
resource "aws_autoscaling_group" "blue" {
  count = var.deployment_color == "blue" ? 1 : 0
  ...
}

resource "aws_autoscaling_group" "green" {
  count = var.deployment_color == "green" ? 1 : 0
  ...
}

# Weighted listener rule
resource "aws_lb_listener_rule" "weighted_routing" {
  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.blue.arn
        weight = var.blue_weight
      }
      target_group {
        arn    = aws_lb_target_group.green.arn
        weight = var.green_weight
      }
    }
  }
}
```

#### 1.2 Add Variables
**File**: `aws/modules/composition/envoy-proxy/variables.tf`

**New Variables**:
```hcl
variable "deployment_color" {
  description = "Deployment color for blue-green strategy"
  type        = string
  default     = "blue"
  validation {
    condition     = contains(["blue", "green"], var.deployment_color)
    error_message = "deployment_color must be either 'blue' or 'green'"
  }
}

variable "blue_weight" {
  description = "Traffic weight for blue target group (0-100)"
  type        = number
  default     = 100
}

variable "green_weight" {
  description = "Traffic weight for green target group (0-100)"
  type        = number
  default     = 0
}

variable "enable_instance_refresh" {
  description = "Enable instance refresh (should be false for blue-green)"
  type        = bool
  default     = false
}
```

#### 1.3 Update Outputs
**File**: `aws/modules/composition/envoy-proxy/outputs.tf`

**New Outputs**:
```hcl
output "blue_asg_name" {
  value = try(module.asg_blue[0].asg_name, null)
}

output "green_asg_name" {
  value = try(module.asg_green[0].asg_name, null)
}

output "blue_target_group_arn" {
  value = aws_lb_target_group.blue.arn
}

output "green_target_group_arn" {
  value = aws_lb_target_group.green.arn
}

output "active_deployment_color" {
  value = var.deployment_color
}

output "alb_listener_arn" {
  value = module.alb_listener.listener_arn
}
```

#### 1.4 Create CloudWatch Alarms
**File**: `aws/modules/composition/envoy-proxy/cloudwatch.tf` (new file)

**Alarms**:
```hcl
# Target 5xx error rate alarm
resource "aws_cloudwatch_metric_alarm" "target_5xx_errors" {
  alarm_name          = "${var.name}-${var.deployment_color}-target-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert when target 5xx errors exceed threshold"

  dimensions = {
    LoadBalancer = module.alb.alb_arn_suffix
    TargetGroup  = var.deployment_color == "blue" ?
                   aws_lb_target_group.blue.arn_suffix :
                   aws_lb_target_group.green.arn_suffix
  }
}

# Target response time alarm
resource "aws_cloudwatch_metric_alarm" "target_response_time" {
  alarm_name          = "${var.name}-${var.deployment_color}-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1.0  # 1 second
  alarm_description   = "Alert when response time exceeds 1 second"

  dimensions = {
    LoadBalancer = module.alb.alb_arn_suffix
    TargetGroup  = var.deployment_color == "blue" ?
                   aws_lb_target_group.blue.arn_suffix :
                   aws_lb_target_group.green.arn_suffix
  }
}

# Unhealthy host count alarm
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.name}-${var.deployment_color}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Alert when unhealthy hosts detected"

  dimensions = {
    LoadBalancer = module.alb.alb_arn_suffix
    TargetGroup  = var.deployment_color == "blue" ?
                   aws_lb_target_group.blue.arn_suffix :
                   aws_lb_target_group.green.arn_suffix
  }
}

# Request count anomaly detection
resource "aws_cloudwatch_metric_alarm" "request_count_anomaly" {
  alarm_name          = "${var.name}-${var.deployment_color}-request-anomaly"
  comparison_operator = "LessThanLowerThreshold"
  evaluation_periods  = 2
  threshold_metric_id = "e1"
  alarm_description   = "Alert on anomalous request count drop"

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
    label       = "Request Count (Expected)"
    return_data = true
  }

  metric_query {
    id          = "m1"
    return_data = true
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 300
      stat        = "Sum"

      dimensions = {
        LoadBalancer = module.alb.alb_arn_suffix
      }
    }
  }
}
```

#### 1.5 Update Live Environment Configuration
**File**: `aws/live/dev/eu-central-1/envoy-proxy/terraform.tfvars`

**Changes**:
```hcl
# Disable instance refresh for blue-green deployments
enable_instance_refresh = false

# Add blue-green configuration
deployment_color = "blue"  # Will be toggled by deployment script
blue_weight      = 100
green_weight     = 0
```

### Phase 2: Deployment Scripts

#### 2.1 Main Blue-Green Deployment Script
**File**: `scripts/envoy-blue-green-deploy.sh`

**Script Structure**:
```bash
#!/bin/bash
set -euo pipefail

# Configuration
REGION="eu-central-1"
ENVIRONMENT="dev"
TERRAFORM_DIR="aws/live/${ENVIRONMENT}/${REGION}/envoy-proxy"
TRAFFIC_STEPS=(1 5 10 25 50 100)
WAIT_TIME=300  # 5 minutes in seconds
ROLLBACK_WINDOW=3600  # 1 hour in seconds

# Functions:
# - detect_active_color()      : Determine current blue/green deployment
# - create_new_asg()           : Run terraform apply for opposite color
# - wait_for_healthy_targets() : Poll target group health
# - shift_traffic()            : Update ALB listener weights
# - validate_deployment()      : Run all health checks
# - check_cloudwatch_alarms()  : Verify no alarms in ALARM state
# - custom_health_check()      : Deep validation script
# - manual_approval_gate()     : Wait for user confirmation
# - rollback()                 : Revert traffic to old ASG
# - cleanup_old_asg()          : Scale down and schedule deletion
# - main()                     : Orchestrate entire deployment

# Main deployment flow
main() {
  log "INFO" "Starting blue-green deployment for Envoy"

  # Step 1: Detect current deployment
  CURRENT_COLOR=$(detect_active_color)
  NEW_COLOR=$(get_opposite_color "$CURRENT_COLOR")
  log "INFO" "Current: $CURRENT_COLOR, Deploying: $NEW_COLOR"

  # Step 2: Create new ASG
  log "INFO" "Creating $NEW_COLOR ASG"
  create_new_asg "$NEW_COLOR" || {
    log "ERROR" "Failed to create $NEW_COLOR ASG"
    exit 1
  }

  # Step 3: Wait for new ASG to be healthy
  log "INFO" "Waiting for $NEW_COLOR targets to become healthy"
  wait_for_healthy_targets "$NEW_COLOR" || {
    log "ERROR" "Targets failed health checks"
    rollback "$CURRENT_COLOR"
    exit 1
  }

  # Step 4: Gradual traffic shift
  for WEIGHT in "${TRAFFIC_STEPS[@]}"; do
    log "INFO" "Shifting traffic: $NEW_COLOR=$WEIGHT%, $CURRENT_COLOR=$((100-WEIGHT))%"

    shift_traffic "$NEW_COLOR" "$WEIGHT" "$CURRENT_COLOR" "$((100-WEIGHT))" || {
      log "ERROR" "Traffic shift failed"
      rollback "$CURRENT_COLOR"
      exit 1
    }

    # Manual approval at 50%
    if [ "$WEIGHT" -eq 50 ]; then
      manual_approval_gate || {
        log "WARN" "Manual approval rejected, rolling back"
        rollback "$CURRENT_COLOR"
        exit 1
      }
    fi

    # Wait and validate
    if [ "$WEIGHT" -lt 100 ]; then
      log "INFO" "Waiting ${WAIT_TIME}s for validation"
      sleep "$WAIT_TIME"
    fi

    validate_deployment "$NEW_COLOR" || {
      log "ERROR" "Validation failed at ${WEIGHT}%"
      rollback "$CURRENT_COLOR"
      exit 1
    }
  done

  # Step 5: Final validation at 100%
  log "INFO" "Running final validation"
  validate_deployment "$NEW_COLOR" || {
    log "ERROR" "Final validation failed"
    rollback "$CURRENT_COLOR"
    exit 1
  }

  # Step 6: Cleanup old ASG
  log "INFO" "Scaling down $CURRENT_COLOR ASG to 0"
  cleanup_old_asg "$CURRENT_COLOR" "$ROLLBACK_WINDOW"

  log "SUCCESS" "Blue-green deployment completed: $NEW_COLOR is now active"
}

# Execute
main "$@"
```

#### 2.2 Validation Script
**File**: `scripts/validate-envoy-health.sh`

**Functionality**:
```bash
#!/bin/bash
# Deep health validation for Envoy deployment

validate_envoy_health() {
  local DEPLOYMENT_COLOR=$1
  local TARGET_GROUP_ARN=$2

  # 1. Check ALB target health
  check_target_health "$TARGET_GROUP_ARN"

  # 2. Validate Envoy admin endpoint
  check_envoy_admin "$DEPLOYMENT_COLOR"

  # 3. Test upstream connectivity
  check_upstream_connectivity "$DEPLOYMENT_COLOR"

  # 4. Compare metrics (if both deployments running)
  compare_deployment_metrics "$DEPLOYMENT_COLOR"

  # 5. Verify CloudWatch alarms
  check_cloudwatch_alarms "$DEPLOYMENT_COLOR"

  # Return 0 if all checks pass
  return 0
}
```

### Phase 3: Argo Workflow

#### 3.1 Workflow Definition
**File**: `argo-workflows/envoy-blue-green-deployment.yaml`

**Workflow**:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: envoy-blue-green-
  namespace: argo
spec:
  entrypoint: blue-green-deployment

  # Parameters
  arguments:
    parameters:
    - name: environment
      value: dev
    - name: region
      value: eu-central-1
    - name: config-version
      value: "latest"

  # Service account with AWS credentials
  serviceAccountName: terraform-deployer

  # Workflow steps
  templates:
  - name: blue-green-deployment
    steps:
    # Step 1: Pre-deployment validation
    - - name: validate-prerequisites
        template: validate-prereqs

    # Step 2: Detect current color and create new ASG
    - - name: create-new-asg
        template: terraform-apply
        arguments:
          parameters:
          - name: new-color
            value: "{{steps.detect-color.outputs.parameters.new-color}}"

    # Step 3-8: Traffic shifting (1, 5, 10, 25, 50, 100%)
    - - name: shift-traffic-1
        template: shift-and-validate
        arguments:
          parameters:
          - name: weight
            value: "1"

    - - name: shift-traffic-5
        template: shift-and-validate
        arguments:
          parameters:
          - name: weight
            value: "5"

    - - name: shift-traffic-10
        template: shift-and-validate
        arguments:
          parameters:
          - name: weight
            value: "10"

    - - name: shift-traffic-25
        template: shift-and-validate
        arguments:
          parameters:
          - name: weight
            value: "25"

    # Manual approval at 50%
    - - name: approval-gate
        template: manual-approval

    - - name: shift-traffic-50
        template: shift-and-validate
        arguments:
          parameters:
          - name: weight
            value: "50"

    - - name: shift-traffic-100
        template: shift-and-validate
        arguments:
          parameters:
          - name: weight
            value: "100"

    # Step 9: Final validation
    - - name: final-validation
        template: validate-deployment

    # Step 10: Cleanup old ASG
    - - name: cleanup-old-asg
        template: cleanup

    # Step 11: Schedule deletion (1 hour later)
    - - name: schedule-deletion
        template: scheduled-cleanup

  # Template definitions
  - name: shift-and-validate
    inputs:
      parameters:
      - name: weight
    container:
      image: hashicorp/terraform:latest
      command: [bash]
      args:
      - /scripts/envoy-blue-green-deploy.sh
      - shift-traffic
      - "{{inputs.parameters.weight}}"
      volumeMounts:
      - name: scripts
        mountPath: /scripts
      - name: aws-credentials
        mountPath: /root/.aws

    # Wait 5 minutes
    - - name: wait
        delay: "300s"

    # Validate
    - - name: validate
        template: validate-deployment

    # On failure: rollback
    onExit: rollback-on-failure

  - name: manual-approval
    suspend: {}

  - name: validate-deployment
    script:
      image: amazon/aws-cli:latest
      command: [bash]
      source: |
        /scripts/validate-envoy-health.sh {{workflow.parameters.environment}}
      volumeMounts:
      - name: scripts
        mountPath: /scripts

    # Retry on failure
    retryStrategy:
      limit: 3
      retryPolicy: OnFailure
      backoff:
        duration: 60
        factor: 2

  - name: rollback-on-failure
    container:
      image: hashicorp/terraform:latest
      command: [bash]
      args:
      - /scripts/envoy-blue-green-deploy.sh
      - rollback

  # Notifications
  - name: notify-success
    container:
      image: curlimages/curl:latest
      command: [sh, -c]
      args:
      - |
        curl -X POST $SLACK_WEBHOOK_URL \
          -H 'Content-Type: application/json' \
          -d '{"text":"Envoy deployment successful: {{workflow.parameters.environment}}"}'

  - name: notify-failure
    container:
      image: curlimages/curl:latest
      command: [sh, -c]
      args:
      - |
        curl -X POST $SLACK_WEBHOOK_URL \
          -H 'Content-Type: application/json' \
          -d '{"text":"Envoy deployment FAILED: {{workflow.parameters.environment}}"}'

  # Volumes
  volumes:
  - name: scripts
    configMap:
      name: deployment-scripts
  - name: aws-credentials
    secret:
      secretName: aws-credentials

  # On workflow completion
  onExit: cleanup-workflow

# ConfigMap for scripts
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: deployment-scripts
  namespace: argo
data:
  envoy-blue-green-deploy.sh: |
    # Include full script here
  validate-envoy-health.sh: |
    # Include validation script here
```

### Phase 4: Documentation

#### 4.1 Deployment Runbook
**File**: `docs/envoy-deployment-runbook.md`

**Contents**:
- Overview of blue-green architecture
- Prerequisites and access requirements
- Step-by-step deployment instructions
- Rollback procedures
- Troubleshooting guide
- Emergency contacts

#### 4.2 Architecture Diagram
**File**: `docs/diagrams/envoy-blue-green-architecture.md`

**Diagrams**:
- Current vs proposed architecture
- Traffic flow during deployment
- Failure and rollback scenarios
- Component interactions

### Phase 5: Testing Plan

#### 5.1 Unit Tests
- Test each bash function independently
- Mock AWS CLI responses
- Validate Terraform plan output

#### 5.2 Integration Tests
- Deploy to dev environment
- Simulate traffic during deployment
- Trigger intentional failures to test rollback
- Verify CloudWatch alarms trigger correctly

#### 5.3 Load Testing
- Generate sustained load during deployment
- Measure error rates at each traffic percentage
- Validate no dropped requests during shift

## Implementation Timeline

### Week 1: Terraform Changes
- [ ] Update envoy-proxy module with blue-green support
- [ ] Add CloudWatch alarms
- [ ] Update variables and outputs
- [ ] Test terraform plan/apply in dev

### Week 2: Scripts Development
- [ ] Write bash deployment script
- [ ] Write validation script
- [ ] Create unit tests
- [ ] Local testing with mocked AWS CLI

### Week 3: Argo Workflow
- [ ] Create workflow YAML
- [ ] Set up ConfigMaps and Secrets
- [ ] Deploy to Argo namespace
- [ ] Test workflow execution

### Week 4: Integration Testing
- [ ] End-to-end deployment in dev
- [ ] Test rollback scenarios
- [ ] Load testing
- [ ] Fix issues and refine

### Week 5: Documentation & Handoff
- [ ] Complete runbook documentation
- [ ] Create architecture diagrams
- [ ] Team training session
- [ ] Production readiness review

## Rollback Procedures

### Automatic Rollback (Script-Triggered)
When validation fails at any step:
1. Script detects failure (health check, alarm, or custom validation)
2. Immediately shifts 100% traffic back to old deployment
3. Scales down new ASG to 0
4. Logs failure details and sends alert
5. Preserves new ASG for debugging (manual deletion required)

### Manual Rollback (Human-Triggered)
During manual approval gate or any time during deployment:
1. Cancel Argo workflow or press Ctrl+C on script
2. Run: `./scripts/envoy-blue-green-deploy.sh rollback <current-color>`
3. Script shifts 100% traffic to specified color
4. Validates rollback succeeded
5. Cleanup decision left to operator

### Emergency Rollback (Production Incident)
If deployed successfully but issues discovered later:
1. Old ASG still exists at 0 capacity (1-hour window)
2. Scale up old ASG: `aws autoscaling set-desired-capacity --auto-scaling-group-name <old-asg> --desired-capacity <N>`
3. Wait for instances to become healthy (2-5 minutes)
4. Shift traffic: `aws elbv2 modify-listener ...` (100% to old)
5. Scale down new ASG
6. Investigate and fix issues

## Monitoring & Alerting

### Key Metrics to Monitor
- **Target Health**: Healthy vs Unhealthy host count per TG
- **Error Rates**: 4xx, 5xx at ALB and target level
- **Latency**: p50, p95, p99 response times
- **Request Count**: Total requests per minute
- **Connection Metrics**: Active connections, new connections/sec

### Alert Channels
- Slack: `#envoy-deployments` channel
- PagerDuty: On-call engineer for production
- Email: DevOps team distribution list

### Dashboard
Create CloudWatch dashboard with:
- Side-by-side blue/green metrics
- Traffic distribution percentage
- Real-time health status
- Deployment timeline annotations

## Success Criteria

### Deployment Success
- ✅ All target group health checks passing
- ✅ No CloudWatch alarms in ALARM state
- ✅ Error rate < 0.1%
- ✅ p95 latency within 10% of baseline
- ✅ Manual validation approved
- ✅ Old ASG successfully scaled to 0

### Rollback Success
- ✅ Traffic shifted back to old deployment
- ✅ All old instances healthy
- ✅ Service restored within 5 minutes
- ✅ Incident logged and reviewed

## Security Considerations

### IAM Permissions
Argo workflow service account needs:
- `autoscaling:*` on envoy ASGs
- `elasticloadbalancing:ModifyListener` on ALB
- `elasticloadbalancing:ModifyTargetGroup*` on target groups
- `cloudwatch:DescribeAlarms` for alarm checks
- `cloudwatch:PutMetricData` for custom metrics
- `s3:GetObject` on config bucket
- `ssm:GetParameter` for secrets

### Network Security
- Scripts run from within VPC (via Argo pods in EKS)
- No public internet access required
- All AWS API calls via VPC endpoints

### Audit Trail
- All deployments logged to CloudWatch Logs
- Terraform state changes tracked
- Argo workflow artifacts preserved for 30 days
- Manual approvals logged with username and timestamp

## Cost Implications

### During Deployment (~30 minutes)
- **Temporary**: Running both blue and green ASGs simultaneously
- **Extra EC2 instances**: 2× capacity for 30 minutes
- **Cost**: ~$0.02 per deployment (t3.small in us-east-1)

### Rollback Window (1 hour)
- **Old ASG at 0 capacity**: No instance costs
- **ASG metadata**: Free
- **Total**: $0

### Overall
- Minimal cost increase vs instance refresh
- Better reliability justifies slight cost overhead

## Future Enhancements

### Phase 2 Improvements
- [ ] Automated canary analysis (statistical comparison)
- [ ] Integration with feature flags for instant rollback
- [ ] Multi-region deployments
- [ ] Blue-green for multiple services simultaneously
- [ ] Progressive delivery with user segmentation
- [ ] Slack bot for approvals and notifications
- [ ] Grafana dashboards for deployment visibility

### Advanced Features
- [ ] A/B testing integration
- [ ] Shadow traffic mode (mirror requests to new deployment)
- [ ] Automated performance regression detection
- [ ] Self-healing deployments (auto-rollback on anomalies)

---

## Quick Start Guide

### Trigger Deployment

**Via Argo CLI**:
```bash
argo submit argo-workflows/envoy-blue-green-deployment.yaml \
  --parameter environment=dev \
  --parameter region=eu-central-1 \
  --parameter config-version=v2.0.1
```

**Via kubectl**:
```bash
kubectl create -f argo-workflows/envoy-blue-green-deployment.yaml
```

**Watch Progress**:
```bash
argo watch @latest
```

**Manual Approval**:
```bash
# Workflow will pause at 50% traffic
# Approve via Argo UI or CLI:
argo resume <workflow-name>
```

### Monitor Deployment

**CloudWatch Dashboard**:
- Navigate to CloudWatch → Dashboards → "Envoy Blue-Green"
- View real-time metrics for both deployments

**Logs**:
```bash
# Argo workflow logs
argo logs <workflow-name> --follow

# Script logs in CloudWatch
aws logs tail /argo/envoy-deployment --follow
```

**Manual Checks**:
```bash
# Check ASG status
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names dev-hyperswitch-envoy-blue dev-hyperswitch-envoy-green

# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn <blue-tg-arn>

# Check listener weights
aws elbv2 describe-rules \
  --listener-arn <listener-arn>
```

---

## Appendix

### A. File Structure
```
terraform/
├── aws/
│   ├── modules/
│   │   └── composition/
│   │       └── envoy-proxy/
│   │           ├── main.tf (modified)
│   │           ├── variables.tf (modified)
│   │           ├── outputs.tf (modified)
│   │           └── cloudwatch.tf (new)
│   └── live/
│       └── dev/
│           └── eu-central-1/
│               └── envoy-proxy/
│                   └── terraform.tfvars (modified)
├── scripts/
│   ├── envoy-blue-green-deploy.sh (new)
│   └── validate-envoy-health.sh (new)
├── argo-workflows/
│   └── envoy-blue-green-deployment.yaml (new)
└── docs/
    ├── envoy-blue-green-deployment-plan.md (this file)
    ├── envoy-deployment-runbook.md (new)
    └── diagrams/
        └── envoy-blue-green-architecture.md (new)
```

### B. Prerequisites Checklist
- [ ] Argo Workflows installed in EKS cluster
- [ ] AWS credentials configured for Argo service account
- [ ] Terraform backend configured and accessible
- [ ] CloudWatch alarms SNS topic created
- [ ] Slack webhook URL configured (optional)
- [ ] Team trained on deployment process
- [ ] Rollback procedures documented and tested

### C. References
- [AWS ALB Weighted Target Groups](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-routing-configuration)
- [Argo Workflows Documentation](https://argoproj.github.io/argo-workflows/)
- [Terraform AWS Provider - ASG](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group)
- [Blue-Green Deployment Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)

---

**Document Version**: 1.0
**Last Updated**: 2025-11-13
**Author**: DevOps Team
**Status**: Planning Phase
