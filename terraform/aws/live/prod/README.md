# Production Environment Configuration

This directory is reserved for **Production environment** configurations.

## Setup Instructions

To set up the production environment, follow the **dev environment** as a reference template.

### Steps to Create Production Environment

1. **Copy the dev environment structure:**
   ```bash
   # From the terraform/aws/live directory
   cp -r dev/eu-central-1/squid-proxy prod/eu-central-1/squid-proxy
   cp -r dev/eu-central-1/envoy-proxy prod/eu-central-1/envoy-proxy
   ```

2. **Update environment-specific values in terraform.tfvars:**
   - Change `environment = "dev"` to `environment = "prod"`
   - Update all `XXXXXXXXXXXXX` placeholders with your **production environment** resources:
     - VPC ID
     - Subnet IDs (proxy subnets, LB subnets)
     - Security Group IDs
     - AMI IDs
     - EKS worker subnet CIDRs
     - DNS names (CloudFront, internal ALB)
   - **Scale up resources for production:**
     - Increase `desired_capacity`, `min_size`, `max_size`
     - Use larger instance types if needed (e.g., `t3.medium` or `t3.large`)
     - Enable detailed monitoring: `enable_detailed_monitoring = true`

3. **Configure remote state backend** (REQUIRED for production):

   Create a `backend.tf` file in each service directory:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "your-terraform-state-bucket-prod"
       key            = "prod/eu-central-1/squid-proxy/terraform.tfstate"
       region         = "eu-central-1"
       encrypt        = true
       dynamodb_table = "terraform-state-lock-prod"

       # Additional production safeguards
       kms_key_id = "arn:aws:kms:eu-central-1:ACCOUNT:key/KEY-ID"  # Optional but recommended
     }
   }
   ```

4. **Enable instance refresh for zero-downtime updates:**
   ```hcl
   enable_instance_refresh = true

   instance_refresh_preferences = {
     min_healthy_percentage = 90  # Higher for production
     instance_warmup        = 300
     checkpoint_percentages = [50]
     checkpoint_delay       = 600  # Longer delay for validation
   }
   ```

5. **Review the configuration carefully:**
   ```bash
   cd prod/eu-central-1/squid-proxy
   terraform init
   terraform plan -out=prod.tfplan

   # Review the plan thoroughly
   terraform show prod.tfplan
   ```

6. **Apply with approval workflow:**
   ```bash
   # Apply only after review and approval
   terraform apply prod.tfplan
   ```

## Production Environment Characteristics

- **Purpose:** Live production workloads
- **Stability:** High - changes require approval and testing
- **Resource Sizing:** Production-grade sizing
- **Availability:** High availability with multi-AZ deployment
- **Access:** Restricted to operations team only

## Production Best Practices

### Change Management
- ✅ Always test changes in dev/integ first
- ✅ Require peer review for all production changes
- ✅ Use `terraform plan` and save the plan file
- ✅ Apply changes during maintenance windows
- ✅ Have rollback plan ready

### Monitoring & Alerting
- ✅ Enable detailed CloudWatch monitoring
- ✅ Set up alarms for ASG health, NLB health
- ✅ Monitor Squid/Envoy logs
- ✅ Configure alerting to ops team

### Backup & Disaster Recovery
- ✅ Enable S3 versioning for state bucket
- ✅ Enable S3 replication for state bucket (cross-region)
- ✅ Regular snapshots of critical data
- ✅ Document disaster recovery procedures

### Security
- ✅ Use KMS encryption for Terraform state
- ✅ Enable CloudTrail for audit logging
- ✅ Restrict IAM permissions (least privilege)
- ✅ Enable VPC Flow Logs
- ✅ Regular security audits

## Reference

See the [dev environment configuration](../dev/eu-central-1/) for:
- Complete terraform.tfvars examples
- Module usage patterns
- Configuration file templates
- Testing procedures

## Security Considerations

⚠️ **CRITICAL:** This directory contains configurations for your production environment.

- **MUST** store in a **private repository** with strict access controls
- **MUST** enable branch protection on main/master branch
- **MUST** require code review and approvals for all changes
- **MUST** use MFA for all production access
- **NEVER** commit sensitive values to version control
- Use AWS Secrets Manager or Parameter Store for secrets
- Enable encryption at rest for all data stores

## Incident Response

In case of production issues:

1. Check CloudWatch logs for Squid/Envoy instances
2. Verify NLB target health
3. Check ASG instance health
4. Review recent Terraform changes
5. Rollback if necessary: `terraform apply` with previous state

## Related Documentation

- [Dev Environment Setup](../dev/eu-central-1/)
- [Squid Proxy Testing Guide](../../../SQUID_PROXY_TESTING_GUIDE.md)
- [Module Documentation](../../modules/README.md)

## Emergency Contacts

- Infrastructure Team: [Add contact info]
- On-Call Engineer: [Add on-call rotation]
- Incident Management: [Add incident management process]
