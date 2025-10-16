#!/bin/bash
set -e

# Variables from Terraform
CONFIG_BUCKET="${config_bucket}"
LOGS_BUCKET="${logs_bucket}"
ENVOY_ADMIN_PORT="${envoy_admin_port}"
ENVOY_LISTENER_PORT="${envoy_listener_port}"
ENVIRONMENT="${environment}"
REGION="${region}"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/envoy-init.log
}

log "Starting Envoy proxy initialization for environment: $ENVIRONMENT"

# Update system packages
log "Updating system packages..."
yum update -y || apt-get update -y

# Install required packages
log "Installing required packages..."
if command -v yum &> /dev/null; then
    yum install -y aws-cli amazon-cloudwatch-agent
else
    apt-get install -y awscli amazon-cloudwatch-agent
fi

# Install Envoy
log "Installing Envoy proxy..."
if command -v yum &> /dev/null; then
    # Amazon Linux/RHEL
    curl -L https://getenvoy.io/cli | bash -s -- -b /usr/local/bin
    getenvoy fetch standard:1.28.0
    cp ~/.getenvoy/builds/standard/1.28.0/linux_glibc/bin/envoy /usr/local/bin/
else
    # Debian/Ubuntu
    curl -sL 'https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key' | gpg --dearmor -o /usr/share/keyrings/getenvoy-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/getenvoy-keyring.gpg] https://deb.dl.getenvoy.io/public/deb/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/getenvoy.list
    apt-get update
    apt-get install -y getenvoy-envoy
fi

# Download Envoy configuration from S3
log "Downloading Envoy configuration from s3://$CONFIG_BUCKET/envoy/"
mkdir -p /etc/envoy/
aws s3 sync s3://$CONFIG_BUCKET/envoy/ /etc/envoy/ --region $REGION

# Create envoy user
log "Creating envoy user..."
useradd -r -s /bin/false envoy || true

# Create systemd service for Envoy
log "Creating Envoy systemd service..."
cat > /etc/systemd/system/envoy.service << EOF
[Unit]
Description=Envoy Proxy
After=network.target

[Service]
Type=simple
User=envoy
ExecStart=/usr/local/bin/envoy -c /etc/envoy/envoy.yaml
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Envoy service
log "Enabling and starting Envoy service..."
systemctl daemon-reload
systemctl enable envoy
systemctl start envoy

# Configure log sync to S3
log "Configuring log sync to S3..."
cat > /usr/local/bin/sync-envoy-logs.sh << 'EOFSCRIPT'
#!/bin/bash
LOG_DIR="/var/log/envoy"
S3_BUCKET="${logs_bucket}"
HOSTNAME=$(hostname)
DATE=$(date +%Y-%m-%d)

# Create log directory if it doesn't exist
mkdir -p $LOG_DIR

# Sync logs to S3
aws s3 sync $LOG_DIR s3://$S3_BUCKET/$HOSTNAME/$DATE/ --region ${region}
EOFSCRIPT

chmod +x /usr/local/bin/sync-envoy-logs.sh

# Add cron job for log sync (every hour)
echo "0 * * * * /usr/local/bin/sync-envoy-logs.sh" | crontab -

# Configure CloudWatch agent
log "Configuring CloudWatch agent..."
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json << EOF
{
  "metrics": {
    "namespace": "EnvoyProxy/$ENVIRONMENT",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_IDLE",
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
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/envoy/access.log",
            "log_group_name": "/aws/envoy/$ENVIRONMENT/access",
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

log "Envoy proxy initialization completed successfully!"
log "Envoy admin interface: http://localhost:$ENVOY_ADMIN_PORT"
log "Envoy listener port: $ENVOY_LISTENER_PORT"
