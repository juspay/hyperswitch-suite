#!/bin/bash
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
export STACK_SVC="locker"
export SYSLOG_ROTATION="Disable"
export S3_BUCKET_NAME="NA"
export DATE="06-08-2026"
export REGION="{{region}}"
export SUDO_USER_LIST="{{sudo-user-list}}"
export NORMAL_USER_LIST="NA"
export SSH_SERVICE="SSM"
export ADDITIONAL_INBOUND_PORTS="8080"
export ADDITIONAL_OUTBOUND_PORTS="443,5432"
export VECTOR_S3_PATH="NA"
export BASILISK_CONFIGS_S3_PATH="NA"
export LOCKER_SECRETS="NA"
EOT
# ------------------------------ Initialization Script ------------------------------ #
echo "⏳ Copying initialization scripts..."
cp /home/01-init-script.sh /var/lib/cloud/scripts/per-instance/01-init-script.sh
chmod +x /var/lib/cloud/scripts/per-instance/01-init-script.sh
echo "✅ Mappings complete! Instance ready for Setup"

