# Locker Deployment - Dev Environment

This directory contains the Terraform configuration to deploy the Hyperswitch Locker card vault service in the dev environment.

## Architecture

```
┌─────────────────────┐
│    Jump Host        │
│  (SSH Access)       │
└─────────┬───────────┘
          │
          │ (SSH - Port 22)
          ▼
┌─────────────────────┐       ┌─────────────────────┐
│  Network Load       │──────▶│  Locker Instance    │
│  Balancer (NLB)     │       │  - Private Subnet   │
│  - Listeners        │       │  - Port 8080        │
└─────────────────────┘       │  - Card Vault       │
                              └─────────┬───────────┘
                                        │
                                        │ (Port 5432)
                                        ▼
                                  ┌─────────────┐
                                  │   RDS       │
                                  │  Database   │
                                  └─────────────┘
```

## Components

- **EC2 Instance:** Runs the locker application
- **Network Load Balancer:** Internal load balancer for accessing locker service
- **Security Groups:** Restrict access to jump host (SSH) and NLB
- **IAM Role:** Grants permissions for ECR, S3, KMS, and CloudWatch
- **CloudWatch Logs:** Centralized logging for the instance

## Prerequisites

1. **VPC with Subnets:**
   - Private subnet with NAT gateway (for outbound internet access)
   - RDS database with security group configured

2. **S3 Backend:**
   - S3 bucket: `hyperswitch-dev-terraform-state`
   - Ensure it exists or update `backend.tf`

3. **Dependencies:**
   - Jump host deployed (for SSH access)
   - RDS database (for locker data storage)
   - SSH key pair created in AWS

4. **Locker AMI:**
   - Custom AMI with locker application pre-installed
   - Required dependencies and configuration

5. **IAM Permissions:**
   - Ability to create EC2 instances, IAM roles, security groups, NLB
   - Permissions to access ECR, S3, KMS

## Configuration

Edit `terraform.tfvars` and replace the placeholder values:

```hcl
# Network Configuration
vpc_id           = "vpc-XXXXXXXXXXXXXXXXX"       # Your VPC ID
locker_subnet_id = "subnet-XXXXXXXXXXXXXXXXX"    # Private subnet ID

# Instance Configuration
ami_id    = "ami-XXXXXXXXXXXXXXXXX"       # Locker AMI ID
key_name  = "your-key-pair-name"          # SSH key pair

# Security Group Rules
locker_ingress_rules = [
  {
    description = "SSH access from jump host"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    sg_id       = ["sg-XXXXXXXXXXXXXXXXX"]  # Jump host SG ID
  }
]

locker_egress_rules = [
  {
    description = "HTTPS access for ECR, S3, and AWS services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr        = ["0.0.0.0/0"]
  },
  {
    description = "PostgreSQL access to RDS database"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    sg_id       = ["sg-XXXXXXXXXXXXXXXXX"]  # RDS SG ID
  }
]

nlb_ingress_rules = [
  {
    description = "HTTPS access from jump host"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    sg_id       = ["sg-XXXXXXXXXXXXXXXXX"]  # Jump host SG ID
  }
]

# NLB Listeners Configuration (Optional)
nlb_listeners = [
  {
    port     = 443
    protocol = "TCP"
  },
  {
    port              = 8443
    protocol          = "TLS"
    certificate_arn   = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }
]
```

### Security Group Rules

The module uses a flexible security group rule configuration:

- **Internal Rules (Automatic):** NLB ↔ Locker communication on port 8080 is automatically configured
- **External Rules (Configurable):** Define custom ingress/egress rules via `ingress_rules`, `egress_rules`, `nlb_ingress_rules`, `nlb_egress_rules`

Each rule supports:
- `cidr` - IPv4 CIDR blocks (e.g., `["10.0.0.0/16"]`)
- `sg_id` - Security Group IDs (e.g., `["sg-xxxxx"]`)
- `prefix_list_ids` - VPC Endpoint Prefix Lists (e.g., `["pl-6ea54007"]`)
- `ipv6_cidr` - IPv6 CIDR blocks

### NLB Listeners Configuration

The module supports flexible NLB listener configuration through `nlb_listeners` variable:

- **Default Listener:** Port 443 with TCP protocol (if not specified)
- **Multiple Listeners:** Configure multiple listeners on different ports
- **Protocol Support:** TCP, UDP, TCP_UDP, TLS, HTTP, HTTPS
- **TLS/HTTPS:** Requires `certificate_arn` for SSL/TLS termination
- **Custom Target Groups:** Use `target_group_arn` to route to different target groups

Example configurations:
```hcl
# Simple TCP listener
nlb_listeners = {
  https = {
    port     = 443
    protocol = "TCP"
  }
}

# Multiple listeners with TLS
nlb_listeners = {
  http = {
    port     = 80
    protocol = "TCP"
  },
  https = {
    port              = 443
    protocol          = "TLS"
    certificate_arn   = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  },
  custom_app = {
    port              = 8443
    protocol          = "TCP"
    target_group_arn  = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/custom-tg/1234567890123456"
  }
}
```

## Deployment

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy
terraform apply

# View outputs
terraform output
```

## Accessing Locker

### Via Network Load Balancer

```bash
# Get the NLB DNS name
terraform output locker_nlb_dns

# Access the service (from within VPC or via jump host)
curl https://<nlb-dns-name>
```

### SSH Access (Emergency Only)

```bash
# First, connect to jump host
aws ssm start-session --target <jump-host-instance-id>

# From jump host, SSH to locker instance
ssh -i /path/to/key.pem ec2-user@<locker-private-ip>
```

## Outputs

- `locker_instance_id`: EC2 instance ID
- `locker_private_ip`: Private IP address of the locker instance
- `locker_nlb_dns`: DNS name of the Network Load Balancer
- `locker_nlb_endpoint`: HTTPS endpoint for accessing locker

## Security Considerations

1. **No Public IP:** Locker instance has no public IP address
2. **Private Subnet:** Instance is deployed in a private subnet
3. **Jump Host Access:** SSH access only from jump host
4. **Internal NLB:** Load balancer is internal-only
5. **Least Privilege IAM:** IAM role has minimal required permissions
6. **Encrypted Logs:** CloudWatch logs are stored securely

## Monitoring & Logging

- **CloudWatch Logs:** All system logs are sent to `/aws/ec2/locker/dev`
- **Retention:** Logs retained for 30 days (configurable)
- **Metrics:** Instance monitoring enabled via CloudWatch

## Cleanup

```bash
# Destroy all resources
terraform destroy
```

⚠️ **Warning:** This will permanently delete the locker instance and all associated resources.

## Troubleshooting

### Instance not accessible

1. Check security group rules
2. Verify NLB target health
3. Check instance system/status checks
4. Review CloudWatch logs

### Database connection issues

1. Verify RDS security group allows traffic from locker security group (automatically configured)
2. Check `rds_security_group_id` configuration matches your RDS instance
3. Ensure RDS is in the same VPC

### Permission errors

1. Verify IAM role is attached to the instance
2. Check IAM policies for required permissions
3. Review CloudWatch Logs for specific error messages

## Additional Resources

- [Locker Module Documentation](../../../../modules/composition/locker/)
- [AWS EC2 Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-best-practices.html)
- [Network Load Balancer Guide](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html)
