#! /bin/bash
set -e
set -x

# ------------------------------ Variables ------------------------------ #
BUCKET_NAME="{{bucket-name}}"
LOGS_BUCKET_NAME="{{logs-bucket}}"

# Fetch EC2 region using IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300" -s)
REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)

###### Creating Mappings Script ######
cat <<EOT > /home/ubuntu/mapping.sh
#!/bin/bash
export UPDATE_CLAMAV_DNS="Disable"
export CLAMAV_DNS="NA"
export UPDATE_SURICATA_DNS="Disable"
export SURICATA_DNS="NA"
export UPDATE_WAZUH="{{update-wazuh}}"
export WAZUH_MANAGER_ADDR="{{wazuh-manager-addr}}"
export WAZUH_WORKER_ADDR="{{wazuh-worker-addr}}"
export WAZUH_GROUP="{{wazuh-group}}"
export WAZUH_TAG="{{wazuh-tag}}"
export STACK_SVC="envoy"
export SYSLOG_ROTATION="Enable"
export S3_BUCKET_NAME="${LOGS_BUCKET_NAME}"
export DATE="16-04-2026"
export REGION="${REGION}"
export SUDO_USER_LIST="{{sudo-user-list}}"
export NORMAL_USER_LIST="NA"
export SSH_SERVICE="SSM"
export ADDITIONAL_INBOUND_PORTS="80,443,9901,9273"
export ADDITIONAL_OUTBOUND_PORTS="9092,8090,8091,9200,3100"
export VECTOR_S3_PATH="s3://${BUCKET_NAME}/envoy/vector.toml"
export CERT_NAME="cert.crt"
export KEY_NAME="nopass.key"
export CN_NAME="${REGION}.{{cn-base-domain}}"
export PUSH_ENVOY_LOGS_KAFKA="Disable"
export ENVOY_S3_PATH="s3://${BUCKET_NAME}/envoy/envoy.yaml"
EOT
# ------------------------------ Initialization Script ------------------------------ #
echo "⏳ Copying initialization scripts..."
cp /home/01-init-script.sh /var/lib/cloud/scripts/per-instance/01-init-script.sh
chmod +x /var/lib/cloud/scripts/per-instance/01-init-script.sh
echo "✅ Mappings complete! Instance ready for Setup"

export AWS_DEFAULT_REGION=${REGION}
rm -rf /etc/envoy/envoy-config-template.yaml
aws s3 cp s3://${BUCKET_NAME}/envoy/envoy.yaml /home/ubuntu/envoy.yaml
cp /home/ubuntu/envoy.yaml /etc/envoy/envoy-config-template.yaml
chmod ug+rw /etc/envoy/envoy-config-template.yaml
sudo chown envoy:envoy /etc/envoy/envoy-config-template.yaml
sudo chown envoy:envoy /etc/envoy/envoy.yaml

mkdir -p /etc/envoy/lua
aws s3 cp s3://${BUCKET_NAME}/envoy/authentication_with_cug_header.lua /etc/envoy/lua/auth.lua
aws s3 cp s3://${BUCKET_NAME}/envoy/no-auth.lua /etc/envoy/lua/no-auth.lua
chmod ug+rw /etc/envoy/lua/auth.lua
chmod ug+rw /etc/envoy/lua/no-auth.lua
sudo chown envoy:envoy /etc/envoy/lua/auth.lua
sudo chown envoy:envoy /etc/envoy/lua/no-auth.lua

sudo systemctl restart envoy.service

echo "The config has been Changed Please Verify"

#Adding config for vector
aws s3 cp  s3://${BUCKET_NAME}/envoy/vector.toml /home/ubuntu/vector.toml
cp /home/ubuntu/vector.toml /etc/vector/vector.toml
chmod +r /etc/vector/vector.toml

# Fetch EC2 metadata using IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300" -s)
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
INSTANCE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4)
ASG_NAME=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/tags/instance/aws:autoscaling:groupName)
LT_VERSION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/tags/instance/aws:ec2launchtemplate:version)

cat > /etc/default/metadata <<EOF
METADATA_INSTANCE_ID=${INSTANCE_ID}
METADATA_INSTANCE_IP=${INSTANCE_IP}
METADATA_ASG_NAME=${ASG_NAME}
METADATA_LT_VERSION=${LT_VERSION}
EOF

mkdir -p /etc/systemd/system/vector.service.d
cat > /etc/systemd/system/vector.service.d/environment.conf <<EOF
[Service]
EnvironmentFile=/etc/default/metadata
EOF

sudo systemctl daemon-reload
sudo systemctl restart vector.service
