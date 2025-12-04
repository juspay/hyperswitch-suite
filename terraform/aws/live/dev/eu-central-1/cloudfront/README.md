# CloudFront CDN Module

This directory contains the live layer configuration for CloudFront CDN using the composition module.

## Overview

This configuration demonstrates the template-based approach for managing multiple CloudFront distributions with multiple cache behaviors, origins, and configurations.

## Architecture

The CloudFront module follows the composition pattern:
- **Boilerplate code**: Located in `/modules/composition/cloudfront/`
- **Configuration**: Defined in this live layer (`/live/dev/eu-central-1/cloudfront/`)

## Key Features

### 1. Multiple Distributions
- Support for 10-12 CloudFront distributions
- Each distribution can have different origins, cache behaviors, and configurations

### 2. Template-Based Configuration
- Reusable behavior templates (static_assets, api, admin, media, api_v2)
- Origin templates (s3_assets, alb_api, custom_origin)
- 75% reduction in configuration complexity

### 3. Multiple Origins
- **S3 origins**: With Origin Access Control (OAC) for private bucket access
- **ALB/NLB origins**: For API backends
- **Custom origins**: For external services

### 4. Multiple Cache Behaviors
- Default cache behavior (fallback)
- Ordered cache behaviors (path-based routing)
- Support for different cache policies, TTL values, and response headers

### 5. CloudFront Functions & Lambda@Edge
- Lightweight JavaScript functions for URL redirects, header manipulation
- Lambda@Edge for complex processing (authentication, request/response manipulation)

### 6. Origin Access Control (OAC)
- Automatic OAC creation
- Automatic S3 bucket policy application
- Secure S3 access without exposing bucket publicly

### 7. Response Headers Policies
- CORS configuration for APIs
- Security headers (CSP, HSTS, XSS protection)
- Custom headers and remove headers

### 8. Automatic Invalidation
- Version-based cache invalidation
- Specific path invalidation
- Integration with deployment pipeline

## Usage

### 1. Configure Backend
Update `backend.tf` with your S3 backend configuration:
```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "cloudfront/dev/eu-central-1/terraform.tfstate"
    region = "eu-central-1"
    encrypt = true
  }
}
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Configure Variables
Create `terraform.tfvars` from `terraform.tfvars.example`:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Update the variables with your actual values, or use the YAML configuration (see below).

### 4. Plan
```bash
terraform plan
```

### 5. Apply
```bash
terraform apply
```

### 6. Output Distribution Information
```bash
terraform output distribution_domain_names
terraform output distribution_ids
terraform output invalidation_commands
```

## Using YAML Configuration

For complex configurations, you can use YAML files and load them in `locals.tf`:

```hcl
# Load YAML configuration
config = yamldecode(file("${path.module}/config.yaml"))

# Use in module configuration
distributions = {
  for name, dist in config.distributions :
  name => dist
}
```

See `config.yaml` for a complete example.

## Configuration Structure

### Behavior Templates

Templates define reusable cache behavior configurations:

```hcl
locals {
  behavior_templates = {
    static_assets = {
      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress = true
      cache_policy_id = "Managed-CachingOptimized"
      ttl = {
        min_ttl = 86400
        default_ttl = 31536000
        max_ttl = 31536000
      }
    }
    # ... more templates
  }
}
```

### Using Templates in Distributions

```hcl
distributions = {
  web-app = {
    # ...
    ordered_cache_behaviors = [
      {
        template = "static_assets"
        path_pattern = "/css/*"
        target_origin_id = "s3-assets"
      },
      {
        template = "api"
        path_pattern = "/api/*"
        target_origin_id = "api-v1"
      }
    ]
  }
}
```

## Outputs

The module provides comprehensive outputs:

### Distribution Information
- `distribution_ids`: Map of distribution IDs
- `distribution_domain_names`: Map of distribution domain names
- `distribution_arns`: Map of distribution ARNs
- `distribution_hosted_zone_ids`: Map of hosted zone IDs

### Resources
- `origin_access_control_ids`: Map of OAC IDs
- `cloudfront_function_arns`: Map of CloudFront Function ARNs
- `response_headers_policy_ids`: Map of response headers policy IDs

### Invalidation
- `invalidation_commands`: Commands to manually invalidate caches
- `invalidation_ids`: Map of invalidation IDs

### Logging
- `log_bucket`: Log bucket configuration
- `log_bucket_name`: Log bucket name
- `log_bucket_domain_name`: Log bucket domain name

### Summary
- `configuration_summary`: Summary of CloudFront configuration

## Examples

### Minimal Distribution

```hcl
distributions = {
  minimal = {
    origins = [
      {
        origin_id = "s3-origin"
        type = "s3"
        s3_bucket_domain_name = "my-bucket.s3.amazonaws.com"
        s3_bucket_id = "my-bucket"
        s3_bucket_arn = "arn:aws:s3:::my-bucket"
        origin_access_control_id = "oac-id"
      }
    ]

    default_cache_behavior = {
      target_origin_id = "s3-origin"
      allowed_methods = ["GET", "HEAD"]
      cached_methods = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      ttl = {
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
      }
    }
  }
}
```

### Distribution with Multiple Origins

```hcl
distributions = {
  web-app = {
    origins = [
      {
        origin_id = "s3-assets"
        type = "s3"
        # ... S3 configuration
      },
      {
        origin_id = "api-v1"
        type = "alb"
        domain_name = "api.example.com"
        custom_origin_config = {
          http_port = 80
          https_port = 443
          origin_protocol_policy = "https-only"
        }
      }
    ]

    ordered_cache_behaviors = [
      {
        template = "static_assets"
        path_pattern = "/static/*"
        target_origin_id = "s3-assets"
      },
      {
        template = "api"
        path_pattern = "/api/*"
        target_origin_id = "api-v1"
      }
    ]
  }
}
```

### Distribution with Lambda@Edge

```hcl
distributions = {
  authenticated = {
    origins = [
      {
        origin_id = "api"
        type = "alb"
        domain_name = "api.example.com"
        custom_origin_config = {
          https_port = 443
          origin_protocol_policy = "https-only"
        }
      }
    ]

    default_cache_behavior = {
      target_origin_id = "api"
      allowed_methods = ["GET", "POST", "PUT", "DELETE"]
      cached_methods = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      ttl = {
        min_ttl = 0
        default_ttl = 300
        max_ttl = 3600
      }
      lambda_function_associations = [
        {
          event_type = "viewer-request"
          lambda_arn = "arn:aws:lambda:region:account:function:auth"
        }
      ]
    }
  }
}
```

## Best Practices

### 1. Use Templates
Always use behavior templates instead of defining full configurations for each behavior.

### 2. Reference Origins
Use origin references instead of duplicating origin configurations.

### 3. Version Invalidation
Use version numbers for invalidation to track changes.

### 4. Secure S3 with OAC
Always use Origin Access Control for S3 origins to prevent direct bucket access.

### 5. Separate Configurations
Use separate files for different distributions in production.

### 6. Use Managed Policies
Use CloudFront managed cache and origin request policies when possible.

### 7. Enable Logging
Enable access logging for all distributions in production.

### 8. Review Quotas
Be aware of CloudFront quotas (25 cache behaviors, 10 origins per distribution).

## Troubleshooting

### Distribution Not Deployed
- Check CloudFront distribution status in AWS Console
- Verify certificate is in us-east-1 region
- Ensure origins are accessible

### Invalidation Failed
- Check invalidation status: `aws cloudfront get-invalidation --distribution-id <id> --id <invalidation-id>`
- Verify paths are correct
- Wait for distribution to be deployed

### 403 Errors from S3
- Verify OAC is created
- Check S3 bucket policy is applied
- Ensure bucket is not publicly accessible

### Cache Not Working
- Check cache behavior configuration
- Verify TTL values
- Check cache policy is correct

## Requirements

- Terraform >= 1.5.7
- AWS provider >= 6.20
- AWS CLI (optional, for manual invalidation)

## Additional Resources

- [AWS CloudFront Developer Guide](https://docs.aws.amazon.com/cloudfront/)
- [Terraform AWS CloudFront Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution)
- [Terraform CloudFront Module](https://registry.terraform.io/modules/terraform-aws-modules/cloudfront/aws/latest)