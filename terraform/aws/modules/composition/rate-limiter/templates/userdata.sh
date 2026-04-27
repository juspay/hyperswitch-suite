#!/bin/bash
set -e

# =============================================================================
# Create Mapping Script with Environment Configuration
# =============================================================================
mkdir -p /home/ubuntu

cat <<'MAPPING_EOF' > /home/ubuntu/mapping.sh
#!/bin/bash
# Wazuh settings
export UPDATE_WAZUH="${update_wazuh}"
export WAZUH_MANAGER_ADDR="${wazuh_manager_addr}"
export WAZUH_WORKER_ADDR="${wazuh_worker_addr}"
export WAZUH_GROUP="${wazuh_group}"
export WAZUH_TAG="${wazuh_tag}"

# Stack and logging settings
export STACK_SVC="${stack_svc}"
export SYSLOG_ROTATION="${syslog_rotation}"
export REGION="${region}"

# User and access settings
export SUDO_USER_LIST="${sudo_user_list}"
export NORMAL_USER_LIST="${normal_user_list}"
export SSH_SERVICE="${ssh_service}"

# Network settings
export ADDITIONAL_INBOUND_PORTS="${additional_inbound_ports}"
export ADDITIONAL_OUTBOUND_PORTS="${additional_outbound_ports}"

# Application configuration paths
export RATELIMIT_ENV_CONFIG_FILE_PATH="${ratelimit_env_config_file_path}"
export RATELIMIT_DESCRIPTOR_FILE_PATH="${ratelimit_descriptor_file_path}"

# ElastiCache connection info
export ELASTICACHE_ENABLED="${elasticache_enabled}"
export ELASTICACHE_PRIMARY_ENDPOINT="${elasticache_primary_endpoint}"
export ELASTICACHE_READER_ENDPOINT="${elasticache_reader_endpoint}"
export ELASTICACHE_PORT="${elasticache_port}"
MAPPING_EOF

chmod +x /home/ubuntu/mapping.sh
chown ubuntu:ubuntu /home/ubuntu/mapping.sh

# =============================================================================
# Initialization Scripts Setup
# =============================================================================
echo "⏳ Copying initialization scripts..."
cp /home/01-init-script.sh /var/lib/cloud/scripts/per-instance/01-init-script.sh
chmod +x /var/lib/cloud/scripts/per-instance/01-init-script.sh
echo "✅ Mappings complete! Instance ready for Setup"
