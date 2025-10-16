#!/bin/bash
set -e

# Variables from Terraform
CONFIG_BUCKET="${config_bucket}"
LOGS_BUCKET="${logs_bucket}"
SQUID_PORT="${squid_port}"
ENVIRONMENT="${environment}"
REGION="${region}"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/squid-init.log
}

log "Starting Squid proxy initialization for environment: $ENVIRONMENT"

# Update system packages
log "Updating system packages..."
yum update -y || apt-get update -y

# Install required packages
log "Installing required packages..."
if command -v yum &> /dev/null; then
    yum install -y squid aws-cli amazon-cloudwatch-agent
else
    apt-get install -y squid awscli amazon-cloudwatch-agent
fi

# Download Squid configuration from S3
log "Downloading Squid configuration from s3://$CONFIG_BUCKET/squid/"
mkdir -p /etc/squid/
aws s3 sync s3://$CONFIG_BUCKET/squid/ /etc/squid/ --region $REGION

# Create squid cache directory
log "Creating Squid cache directory..."
mkdir -p /var/spool/squid
chown -R squid:squid /var/spool/squid

# Initialize Squid cache
log "Initializing Squid cache..."
squid -z

# Enable and start Squid service
log "Enabling and starting Squid service..."
systemctl enable squid
systemctl start squid

# Configure log rotation and S3 sync for logs
log "Configuring log sync to S3..."
cat > /usr/local/bin/sync-squid-logs.sh << 'EOF'
#!/bin/bash
LOG_DIR="/var/log/squid"
S3_BUCKET="${logs_bucket}"
HOSTNAME=$(hostname)
DATE=$(date +%Y-%m-%d)

# Sync logs to S3
aws s3 sync $LOG_DIR s3://$S3_BUCKET/$HOSTNAME/$DATE/ --region ${region}
EOF

chmod +x /usr/local/bin/sync-squid-logs.sh

# Add cron job for log sync (every hour)
echo "0 * * * * /usr/local/bin/sync-squid-logs.sh" | crontab -

# Configure CloudWatch agent for metrics
log "Configuring CloudWatch agent..."
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json << EOF
{
  "metrics": {
    "namespace": "SquidProxy/$ENVIRONMENT",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_IDLE",
            "unit": "Percent"
          },
          {
            "name": "cpu_usage_iowait",
            "rename": "CPU_IOWAIT",
            "unit": "Percent"
          }
        ],
        "totalcpu": false
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED",
            "unit": "Percent"
          }
        ]
      },
      "netstat": {
        "measurement": [
          {
            "name": "tcp_established",
            "rename": "TCP_ESTABLISHED",
            "unit": "Count"
          },
          {
            "name": "tcp_time_wait",
            "rename": "TCP_TIME_WAIT",
            "unit": "Count"
          }
        ]
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/squid/access.log",
            "log_group_name": "/aws/squid/$ENVIRONMENT/access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/squid/cache.log",
            "log_group_name": "/aws/squid/$ENVIRONMENT/cache",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
log "Starting CloudWatch agent..."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

# Health check script
log "Creating health check script..."
cat > /usr/local/bin/squid-health-check.sh << EOF
#!/bin/bash
if systemctl is-active --quiet squid; then
    exit 0
else
    exit 1
fi
EOF

chmod +x /usr/local/bin/squid-health-check.sh

log "Squid proxy initialization completed successfully!"
log "Squid is running on port $SQUID_PORT"
