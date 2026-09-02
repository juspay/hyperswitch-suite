#!/bin/bash
###### Creating Mappings Script ######
cat <<EOT > /home/ubuntu/mapping.sh
#!/bin/bash
export UPDATE_CLAMAV_DNS="Disable"
export CLAMAV_DNS="NA"
export UPDATE_SURICATA_DNS="Disable"
export SURICATA_DNS="NA"
export UPDATE_WAZUH="${update_wazuh}"
export WAZUH_MANAGER_ADDR="${wazuh_manager_addr}"
export WAZUH_WORKER_ADDR="${wazuh_worker_addr}"
export WAZUH_GROUP="${wazuh_group}"
export WAZUH_TAG="${wazuh_tag}"
export STACK_SVC="jump"
export SYSLOG_ROTATION="Disable"
export S3_BUCKET_NAME="NA"
export DATE="06-08-2026"
export REGION="${region}"
export SUDO_USER_LIST="${sudo_user_list}"
export NORMAL_USER_LIST="NA"
export SSH_SERVICE="SSM"
export ADDITIONAL_INBOUND_PORTS=""
export ADDITIONAL_OUTBOUND_PORTS="5432,22,1514,1515"
export VECTOR_S3_PATH="NA"
EOT
# ------------------------------ Initialization Script ------------------------------ #
echo "⏳ Copying initialization scripts..."
cp /home/01-init-script.sh /var/lib/cloud/scripts/per-instance/01-init-script.sh
chmod +x /var/lib/cloud/scripts/per-instance/01-init-script.sh
echo "✅ Mappings complete! Instance ready for Setup"
