#!/bin/bash
set -e

# Variables from template
JUMP_TYPE="${jump_type}"
ENVIRONMENT="${environment}"
CLOUDWATCH_REGION="${cloudwatch_region}"
LOG_GROUP="/aws/ec2/jump-host/$ENVIRONMENT/$JUMP_TYPE"

# Update system
yum update -y

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
rm -f ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/secure",
            "log_group_name": "$LOG_GROUP",
            "log_stream_name": "{instance_id}/secure",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "$LOG_GROUP",
            "log_stream_name": "{instance_id}/messages",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/audit/audit.log",
            "log_group_name": "$LOG_GROUP",
            "log_stream_name": "{instance_id}/audit",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "JumpHost",
    "metrics_collected": {
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MemoryUtilization",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DiskUtilization",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/"
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

# Security hardening
cat >> /etc/ssh/sshd_config <<EOF

# Security hardening
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 60
EOF

# Restart SSH service
systemctl restart sshd

# Enable audit logging
systemctl enable auditd
systemctl start auditd

# Install useful tools
yum install -y \
  tmux \
  vim \
  htop \
  net-tools \
  tcpdump \
  telnet \
  nc \
  jq \
  git

# Create motd
cat > /etc/motd <<EOF
================================================================================
  $JUMP_TYPE Jump Host - $ENVIRONMENT Environment

  This is a bastion host for secure access to private resources.
  All sessions are logged and monitored.

  Access Method: AWS Systems Manager Session Manager
  Managed By: Terraform
================================================================================
EOF

echo "Jump host setup complete for $JUMP_TYPE in $ENVIRONMENT"
