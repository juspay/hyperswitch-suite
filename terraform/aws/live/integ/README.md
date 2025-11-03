# Integration Environment Configuration

This directory is reserved for **Integration/UAT environment** configurations.

## Setup Instructions

To set up the integration environment, follow the **dev environment** as a reference template.

### Steps to Create Integration Environment

1. **Copy the dev environment structure:**
   ```bash
   # From the terraform/aws/live directory
   cp -r dev/eu-central-1/squid-proxy integ/eu-central-1/squid-proxy
   cp -r dev/eu-central-1/envoy-proxy integ/eu-central-1/envoy-proxy
   ```

2. **Update environment-specific values in terraform.tfvars:**
   - Change `environment = "dev"` to `environment = "integ"`
   - Update all `XXXXXXXXXXXXX` placeholders with your **integration environment** resources:
     - VPC ID
     - Subnet IDs (proxy subnets, LB subnets)
     - Security Group IDs
     - AMI IDs
     - EKS worker subnet CIDRs
     - DNS names (CloudFront, internal ALB)

3. **Configure remote state backend** (recommended for non-dev environments):

   Create a `backend.tf` file in each service directory:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "your-terraform-state-bucket-integ"
       key            = "integ/eu-central-1/squid-proxy/terraform.tfstate"
       region         = "eu-central-1"
       encrypt        = true
       dynamodb_table = "terraform-state-lock-integ"
     }
   }
   ```

4. **Review the configuration:**
   ```bash
   cd integ/eu-central-1/squid-proxy
   terraform init
   terraform plan
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply
   ```

## Environment Characteristics

- **Purpose:** Integration testing and UAT
- **Stability:** Moderate - may have frequent updates
- **Resource Sizing:** Similar to production but may be smaller
- **Access:** Limited to QA and development teams

## Reference

See the [dev environment configuration](../dev/eu-central-1/) for:
- Complete terraform.tfvars examples
- Module usage patterns
- Configuration file templates
- Testing procedures

## Security Considerations

⚠️ **IMPORTANT:** This directory may contain sensitive information for your integration environment.

- Store actual values in a **private repository** or use **Terraform Cloud/Enterprise**
- Never commit real AWS resource IDs, DNS names, or AMI IDs to public repositories
- Use secrets management for sensitive data (AWS Secrets Manager, Parameter Store)
- Enable MFA for Terraform state bucket access

## Related Documentation

- [Dev Environment Setup](../dev/eu-central-1/)
- [Squid Proxy Testing Guide](../../../SQUID_PROXY_TESTING_GUIDE.md)
- [Module Documentation](../../modules/README.md)
