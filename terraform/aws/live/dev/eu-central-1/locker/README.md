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
│  - Listeners        │       │  - Port:locker_port │
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
ami_id         = "ami-XXXXXXXXXXXXXXXXX"  # Locker AMI ID
instance_type  = "t3.medium"              # Instance type
instance_count = 1                        # Number of instances (optional, default: 1)
locker_port    = 8080                     # Locker service port (optional, default: 8080)
key_name       = "your-key-pair-name"     # SSH key pair

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

- **Internal Rules (Automatic):** NLB ↔ Locker communication on configured locker_port (default: 8080) is automatically configured
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

### Instance Outputs
- `instance_ids`: List of EC2 instance IDs (all instances)
- `instance_private_ips`: List of private IP addresses of all instances
- `instance_arns`: List of ARNs of all instances
- `locker_port`: Port number used for the locker service

### Legacy Outputs (Backward Compatible)
- `instance_id`: ID of the first locker instance
- `instance_private_ip`: Private IP of the first locker instance
- `instance_arn`: ARN of the first locker instance

### Network Outputs
- `nlb_dns_name`: DNS name of the Network Load Balancer
- `nlb_listener_arns`: ARNs of the NLB listeners
- `security_group_id`: Security group ID of the locker instances
- `subnet_id`: Subnet ID where instances are deployed

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
