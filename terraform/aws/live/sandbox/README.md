# Sandbox Environment Configuration

This directory is reserved for **Sandbox/Experimental environment** configurations.

## Setup Instructions

To set up the sandbox environment, follow the **dev environment** as a reference template.

### Steps to Create Sandbox Environment

1. **Copy the dev environment structure:**
   ```bash
   # From the terraform/aws/live directory
   cp -r dev/eu-central-1/squid-proxy sandbox/eu-central-1/squid-proxy
   cp -r dev/eu-central-1/envoy-proxy sandbox/eu-central-1/envoy-proxy
   ```

2. **Update environment-specific values in terraform.tfvars:**
   - Change `environment = "dev"` to `environment = "sandbox"`
   - Update all `XXXXXXXXXXXXX` placeholders with your **sandbox environment** resources:
     - VPC ID
     - Subnet IDs (proxy subnets, LB subnets)
     - Security Group IDs
     - AMI IDs
     - DNS names (CloudFront, internal ALB)
   - **Consider minimal resource sizing for cost optimization:**
     - Use `desired_capacity = 1` (or even 0 when not in use)
     - Use smaller instance types (e.g., `t3.micro` or `t3.small`)
     - Disable detailed monitoring to save costs

3. **Configure remote state backend** (optional but recommended):

   Create a `backend.tf` file in each service directory:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "your-terraform-state-bucket-sandbox"
       key            = "sandbox/eu-central-1/squid-proxy/terraform.tfstate"
       region         = "eu-central-1"
       encrypt        = true
       dynamodb_table = "terraform-state-lock-sandbox"
     }
   }
   ```

4. **Review the configuration:**
   ```bash
   cd sandbox/eu-central-1/squid-proxy
   terraform init
   terraform plan
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply
   ```

## Environment Characteristics

- **Purpose:** Experimentation, testing new features, proof of concepts
- **Stability:** Low - frequent changes and experiments expected
- **Resource Sizing:** Minimal to save costs
- **Access:** Open to development team for testing
- **Lifecycle:** Resources may be created and destroyed frequently

## Sandbox Best Practices

### Cost Optimization
- ✅ Use minimal instance sizes
- ✅ Scale down to 0 instances when not in use
- ✅ Set up auto-shutdown schedules (e.g., nights and weekends)
- ✅ Use spot instances where appropriate
- ✅ Regularly cleanup unused resources

### Experimentation Freedom
- ✅ Test new Terraform module versions
- ✅ Try different configuration patterns
- ✅ Experiment with new AWS services
- ✅ Break things and learn without fear
- ❌ Don't rely on sandbox for critical testing

### Resource Tagging
Tag all resources appropriately for tracking and cost allocation:
```hcl
tags = {
  Environment = "sandbox"
  Purpose     = "experimentation"
  Owner       = "team-name"
  CostCenter  = "development"
  AutoShutdown = "enabled"
}
```

## Auto-Shutdown Configuration

Consider implementing auto-shutdown to save costs:

```bash
# Example: Scale down ASG at night
# Add to cron or use AWS Lambda

# Scale down (weekdays at 8 PM)
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name sandbox-hyperswitch-squid-asg \
  --desired-capacity 0

# Scale up (weekdays at 8 AM)
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name sandbox-hyperswitch-squid-asg \
  --desired-capacity 1
```

## Cleanup Policy

Sandbox resources should be cleaned up regularly:

- **Weekly:** Review and remove unused resources
- **Monthly:** Consider destroying entire sandbox and rebuilding
- **Before holidays:** Scale down or destroy to save costs

```bash
# Destroy sandbox environment when not needed
terraform destroy
```

## Reference

See the [dev environment configuration](../dev/eu-central-1/) for:
- Complete terraform.tfvars examples
- Module usage patterns
- Configuration file templates
- Testing procedures

## Security Considerations

⚠️ **IMPORTANT:** Even though this is a sandbox environment, follow security best practices:

- Store actual values in a **private repository**
- Don't use production credentials or data
- Implement proper network isolation
- Use separate AWS accounts if possible (recommended)
- Clean up resources regularly to prevent security sprawl

## Common Use Cases

### Testing New Features
```bash
# Test new Squid whitelist domains
# Test new Envoy configurations
# Test ASG scaling behavior
# Test instance refresh with zero downtime
```

### Learning and Training
- Onboard new team members
- Practice Terraform workflows
- Learn AWS services
- Troubleshoot issues in safe environment

### Performance Testing
- Load test proxy configurations
- Test network throughput
- Benchmark different instance types
- Test auto-scaling thresholds

## Resource Lifecycle

Typical sandbox resource lifecycle:

```
Create → Experiment → Test → Learn → Destroy → Repeat
```

Unlike dev/integ/prod, sandbox resources are **ephemeral** and should not be relied upon for long-term testing.

## Related Documentation

- [Dev Environment Setup](../dev/eu-central-1/)
- [Squid Proxy Testing Guide](../../../SQUID_PROXY_TESTING_GUIDE.md)
- [Module Documentation](../../modules/README.md)

## Tips for Effective Sandbox Usage

1. **Document your experiments** - Keep notes on what you're testing
2. **Tag resources clearly** - Know what you created and why
3. **Clean up after yourself** - Don't leave orphaned resources
4. **Share learnings** - Document what worked and what didn't
5. **Cost awareness** - Monitor spending even in sandbox

## Cost Monitoring

Set up billing alerts for sandbox environment:

```bash
# AWS CLI example to create billing alarm
aws cloudwatch put-metric-alarm \
  --alarm-name sandbox-monthly-cost-alert \
  --alarm-description "Alert when sandbox costs exceed $50/month" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --threshold 50 \
  --comparison-operator GreaterThanThreshold
```

## Questions?

For sandbox-specific questions or issues, reach out to your team lead or create a discussion in your team chat.

Happy experimenting! 🚀
