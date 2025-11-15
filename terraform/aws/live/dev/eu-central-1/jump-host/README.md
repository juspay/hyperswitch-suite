# Jump Host Deployment - Dev Environment

This directory contains the Terraform configuration to deploy jump hosts (bastion servers) in the dev environment.

## Architecture

```
Internet
   │
   │ (Session Manager - HTTPS)
   ▼
┌─────────────────────┐
│  External Jump Host │ (Public Subnet)
│  - Public IP        │
│  - Session Manager  │
└─────────┬───────────┘
          │
          │ (SSH - Port 22)
          ▼
┌─────────────────────┐
│  Internal Jump Host │ (Private Subnet)
│  - No Public IP     │
│  - Session Manager  │
└─────────┬───────────┘
          │
          ▼
    Private VPC Resources
```

## Prerequisites

1. **VPC with Subnets:**
   - Public subnet with Internet Gateway (for external jump)
   - Private subnet (for internal jump)

2. **S3 Backend:**
   - S3 bucket: `hyperswitch-dev-terraform-state`
   - Ensure it exists or update `backend.tf`

3. **AWS CLI with Session Manager Plugin:**
   ```bash
   # Install Session Manager plugin
   # https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
   ```

4. **IAM Permissions:**
   - Ability to create EC2 instances, IAM roles, security groups
   - Session Manager permissions (`ssm:StartSession`)

## Configuration

Edit `terraform.tfvars` and replace the placeholder values:

```hcl
vpc_id            = "vpc-XXXXXXXXXXXXXXXXX"  # Your VPC ID
vpc_cidr          = "10.0.0.0/16"            # Your VPC CIDR
public_subnet_id  = "subnet-XXXXXXXXXXXXXXXXX"  # Public subnet
private_subnet_id = "subnet-XXXXXXXXXXXXXXXXX"  # Private subnet
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

## Connecting to Jump Hosts

### External Jump Host (from anywhere)

```bash
# Get the command from outputs
terraform output external_jump_ssm_command

# Or directly
aws ssm start-session --target <external-instance-id>
```

### Internal Jump Host (from external jump or VPC)

```bash
# Get the command from outputs
terraform output internal_jump_ssm_command

# Or directly
aws ssm start-session --target <internal-instance-id>
```

### SSH from External to Internal Jump

```bash
# 1. Connect to external jump via Session Manager
aws ssm start-session --target <external-instance-id>

# 2. Once inside, SSH to internal jump
ssh <internal-jump-private-ip>
```

## Viewing Logs

```bash
# External jump logs
aws logs tail /aws/ec2/jump-host/dev/external --follow

# Internal jump logs
aws logs tail /aws/ec2/jump-host/dev/internal --follow
```

## Security Features

- **No SSH Keys Required:** Session Manager uses IAM authentication
- **No Public SSH Access:** SSH port 22 is not exposed to internet
- **Encrypted Sessions:** All Session Manager traffic is encrypted
- **Audit Logging:** All sessions logged to CloudWatch Logs
- **Security Hardening:** Password authentication disabled, IMDSv2 enforced
- **Network Isolation:** Internal jump only accessible from external jump

## Managing Users

### Grant Access to Jump Hosts

Add IAM policy to users/roles:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "ssm:StartSession",
    "Resource": [
      "arn:aws:ec2:eu-central-1:ACCOUNT-ID:instance/<external-instance-id>",
      "arn:aws:ec2:eu-central-1:ACCOUNT-ID:instance/<internal-instance-id>"
    ]
  }]
}
```

### Create OS-Level Users

```bash
# 1. Connect to jump host via Session Manager
aws ssm start-session --target <instance-id>

# 2. Switch to root
sudo su -

# 3. Create user
useradd -m -s /bin/bash username

# 4. Add SSH public key (optional for SSH between jumps)
mkdir -p /home/username/.ssh
echo "ssh-rsa AAAAB3..." > /home/username/.ssh/authorized_keys
chmod 600 /home/username/.ssh/authorized_keys
chown -R username:username /home/username/.ssh

# 5. Grant sudo access (optional)
usermod -aG sudo username
```

## Monitoring & Alerts

### CloudWatch Metrics

- **Memory Utilization:** `JumpHost` namespace
- **Disk Utilization:** `JumpHost` namespace
- **CPU Utilization:** Default EC2 metrics

### Create Alarms (Optional)

```bash
# Failed SSH attempts alarm
aws cloudwatch put-metric-alarm \
  --alarm-name jump-host-failed-ssh \
  --alarm-description "Alert on failed SSH attempts" \
  --metric-name FailedSSHAttempts \
  --namespace JumpHost \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold
```

## Cost Estimate

- **2 × t3.micro instances:** ~$12/month (on-demand)
- **20 GB EBS volumes:** ~$2/month
- **CloudWatch Logs (5 GB/month):** ~$2.50/month
- **Session Manager:** Free
- **Total:** ~$16.50/month

## Cleanup

```bash
# Destroy all resources
terraform destroy
```

## Troubleshooting

### Cannot connect via Session Manager

1. Check IAM permissions (need `ssm:StartSession`)
2. Verify SSM agent is running on instance
3. Ensure security groups allow HTTPS outbound (port 443)
4. Check CloudWatch logs for errors

### Cannot SSH from external to internal jump

1. Verify security group rules allow SSH from external jump SG
2. Check external jump can resolve internal jump private IP
3. Verify internal jump is running

### Logs not appearing in CloudWatch

1. Check IAM role has CloudWatch Logs permissions
2. Verify CloudWatch agent is running: `systemctl status amazon-cloudwatch-agent`
3. Check agent config: `/opt/aws/amazon-cloudwatch-agent/etc/config.json`

## Additional Resources

- [AWS Session Manager Documentation](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [CloudWatch Agent Configuration](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)
- [Jump Host Best Practices](https://docs.aws.amazon.com/quickstart/latest/linux-bastion/architecture.html)
