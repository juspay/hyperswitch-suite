# =============================================================================
# Dev Hyperswitch stack
# =============================================================================
# Full-parity single-region composition for internal dev / pre-prod / prod
# environments. Unlike [self-host path removed] (BYO-VPC, self-host), this stack
# creates its own VPC: no unit below is passed `vpc_id` / `*_subnet_ids`, so
# every VPC-consuming unit's `dependency.vpc { enabled = ... }` toggle falls
# through to the `vpc-network` unit created here (see e.g.
# units/database/terragrunt.hcl:11-13,41).
#
# Rendered into terraform/aws/live/<env>/<region>/ by
# terraform/aws/live/terragrunt.stack.hcl. Unit `path`s below are load-bearing
# — every unit's `dependency { config_path = "../..." }` is written against
# this exact layout; renaming a path here breaks the dependency graph.
#
#   Phase 1 — Network & DNS:    vpc-network, route53, acm
#   Phase 2 — Data layer:       database, elasticache, efs, kafka, locker
#   Phase 3 — Proxies & access: squid-proxy, envoy-proxy, jump-host
#   Phase 4 — Compute:          application-stack/eks-01
#   Phase 5 — K8s resources:    application-stack/{eks-resources,utils-load-balancer}
#   Phase 6 — Apps:             application-stack/apps/*
#   Phase 7 — Security rules:   security-rules (apply last)
# =============================================================================

# -----------------------------------------------------------------------------
# Phase 1 — Network & DNS
# -----------------------------------------------------------------------------
unit "vpc-network" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/vpc-network?ref=unit/aws/vpc-network-v0.1.11-v1"
  path   = "vpc-network"

  no_dot_terragrunt_stack = true

  # merge() rather than try(values.X, null): a key present-but-null in a
  # unit's values map defeats that unit's own try(values.X, <default>)
  # fallback, because try() only rescues evaluation errors, not a
  # successfully-resolved null. Omitting the key entirely lets the unit's
  # default apply.
  values = merge(
    { vpc_cidr_prefix = values.vpc_cidr_prefix },
    try(values.single_nat_gateway, null) != null ? { single_nat_gateway = values.single_nat_gateway } : {},
    try(values.custom_interface_vpc_endpoints, null) != null ? { custom_interface_vpc_endpoints = values.custom_interface_vpc_endpoints } : {},
  )
}

unit "route53" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/route53?ref=unit/aws/route53-v0.1.0-v1"
  path   = "route53"

  no_dot_terragrunt_stack = true

  values = merge(
    { base_domain = values.base_domain },
    try(values.public_zone_records, null) != null ? { public_zone_records = values.public_zone_records } : {},
    try(values.internal_zone_records, null) != null ? { internal_zone_records = values.internal_zone_records } : {},
  )
}

unit "acm" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/acm?ref=unit/aws/acm-v0.1.0-v1"
  path   = "acm"

  no_dot_terragrunt_stack = true

  values = {
    base_domain = values.base_domain
  }
}

# -----------------------------------------------------------------------------
# Phase 2 — Data layer
# -----------------------------------------------------------------------------
unit "database" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/database?ref=unit/aws/database-v0.1.6-v1"
  path   = "database"

  no_dot_terragrunt_stack = true

  values = merge(
    # merge() arg order matters: database_engine_version (below) overrides the legacy shared db_engine_version.
    try(values.db_instance_class, null) != null ? { db_instance_class = values.db_instance_class } : {},
    try(values.db_engine_version, null) != null ? { engine_version = values.db_engine_version } : {},
    try(values.database_engine_version, null) != null ? { engine_version = values.database_engine_version } : {},
    try(values.db_backup_retention_period, null) != null ? { backup_retention_period = values.db_backup_retention_period } : {},
    try(values.database_storage_type, null) != null ? { storage_type = values.database_storage_type } : {},
    try(values.database_backup_window, null) != null ? { backup_window = values.database_backup_window } : {},
    try(values.database_maintenance_window, null) != null ? { maintenance_window = values.database_maintenance_window } : {},
    try(values.database_performance_insights_retention_period, null) != null ? { performance_insights_retention_period = values.database_performance_insights_retention_period } : {},
  )
}

unit "elasticache" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/elasticache?ref=unit/aws/elasticache-v0.1.5-v1"
  path   = "elasticache"

  no_dot_terragrunt_stack = true

  values = merge(
    {
      cache_node_type = try(values.cache_node_type, null)
    },
    try(values.cache_num_node_groups, null) != null ? { cache_num_node_groups = values.cache_num_node_groups } : {},
    try(values.cache_replicas_per_node_group, null) != null ? { cache_replicas_per_node_group = values.cache_replicas_per_node_group } : {},
    try(values.cache_node_group_configuration, null) != null ? { cache_node_group_configuration = values.cache_node_group_configuration } : {},
    try(values.elasticache_engine_version, null) != null ? { engine_version = values.elasticache_engine_version } : {},
    try(values.elasticache_snapshot_retention_limit, null) != null ? { snapshot_retention_limit = values.elasticache_snapshot_retention_limit } : {},
    try(values.elasticache_snapshot_window, null) != null ? { snapshot_window = values.elasticache_snapshot_window } : {},
    try(values.elasticache_maintenance_window, null) != null ? { maintenance_window = values.elasticache_maintenance_window } : {},
  )
}

unit "efs" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/efs?ref=unit/aws/efs-v0.1.1-v1"
  path   = "efs"

  no_dot_terragrunt_stack = true

  values = merge(
    try(values.efs_performance_mode, null) != null ? { performance_mode = values.efs_performance_mode } : {},
    try(values.efs_throughput_mode, null) != null ? { throughput_mode = values.efs_throughput_mode } : {},
    try(values.efs_lifecycle_transition_to_ia, null) != null ? { lifecycle_transition_to_ia = values.efs_lifecycle_transition_to_ia } : {},
    try(values.efs_lifecycle_transition_to_primary_storage_class, null) != null ? { lifecycle_transition_to_primary_storage_class = values.efs_lifecycle_transition_to_primary_storage_class } : {},
  )
}

unit "kafka" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/kafka?ref=unit/aws/kafka-v0.1.3-v1"
  path   = "kafka"

  no_dot_terragrunt_stack = true

  values = merge(
    {
      broker_ami_id     = try(values.kafka_broker_ami_id, null)
      controller_ami_id = try(values.kafka_controller_ami_id, null)
    },
    try(values.kafka_broker_count, null) != null ? { broker_count = values.kafka_broker_count } : {},
    try(values.kafka_broker_instance_type, null) != null ? { broker_instance_type = values.kafka_broker_instance_type } : {},
    try(values.kafka_broker_data_volume_size, null) != null ? { broker_data_volume_size = values.kafka_broker_data_volume_size } : {},
    try(values.kafka_broker_data_volume_type, null) != null ? { broker_data_volume_type = values.kafka_broker_data_volume_type } : {},
    try(values.kafka_broker_root_volume_size, null) != null ? { broker_root_volume_size = values.kafka_broker_root_volume_size } : {},
    try(values.kafka_broker_root_volume_type, null) != null ? { broker_root_volume_type = values.kafka_broker_root_volume_type } : {},
    try(values.kafka_controller_instance_type, null) != null ? { controller_instance_type = values.kafka_controller_instance_type } : {},
    try(values.kafka_controller_metadata_volume_size, null) != null ? { controller_metadata_volume_size = values.kafka_controller_metadata_volume_size } : {},
    try(values.kafka_controller_metadata_volume_type, null) != null ? { controller_metadata_volume_type = values.kafka_controller_metadata_volume_type } : {},
    try(values.kafka_controller_root_volume_size, null) != null ? { controller_root_volume_size = values.kafka_controller_root_volume_size } : {},
    try(values.kafka_controller_root_volume_type, null) != null ? { controller_root_volume_type = values.kafka_controller_root_volume_type } : {},
  )
}

unit "locker" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/locker?ref=unit/aws/locker-v0.2.9-v1"
  path   = "locker"

  no_dot_terragrunt_stack = true

  values = merge(
    { ami_id = values.ami_id },
    try(values.db_engine_version, null) != null ? { engine_version = values.db_engine_version } : {},
    try(values.locker_instance_type, null) != null ? { instance_type = values.locker_instance_type } : {},
    try(values.locker_backup_retention_period, null) != null ? { backup_retention_period = values.locker_backup_retention_period } : {},
    try(values.locker_db_instance_class, null) != null ? { db_instance_class = values.locker_db_instance_class } : {},
    try(values.locker_storage_type, null) != null ? { storage_type = values.locker_storage_type } : {},
    try(values.locker_log_retention_days, null) != null ? { log_retention_days = values.locker_log_retention_days } : {},
    try(values.locker_backup_window, null) != null ? { backup_window = values.locker_backup_window } : {},
    try(values.locker_maintenance_window, null) != null ? { maintenance_window = values.locker_maintenance_window } : {},
    try(values.wazuh_manager_addr, null) != null ? { wazuh_manager_addr = values.wazuh_manager_addr } : {},
    try(values.wazuh_worker_addr, null) != null ? { wazuh_worker_addr = values.wazuh_worker_addr } : {},
    try(values.wazuh_group, null) != null ? { wazuh_group = values.wazuh_group } : {},
    try(values.wazuh_tag, null) != null ? { wazuh_tag = values.wazuh_tag } : {},
    try(values.sudo_user_list, null) != null ? { sudo_user_list = values.sudo_user_list } : {},
  )
}

# -----------------------------------------------------------------------------
# Phase 3 — Proxies & access
# -----------------------------------------------------------------------------
unit "squid-proxy" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/squid-proxy?ref=unit/aws/squid-proxy-v0.1.6-v1"
  path   = "squid-proxy"

  no_dot_terragrunt_stack = true

  values = merge(
    { ami_id = values.ami_id },
    try(values.squid_instance_type, null) != null ? { instance_type = values.squid_instance_type } : {},
    try(values.squid_min_size, null) != null ? { min_size = values.squid_min_size } : {},
    try(values.squid_max_size, null) != null ? { max_size = values.squid_max_size } : {},
    try(values.squid_desired_capacity, null) != null ? { desired_capacity = values.squid_desired_capacity } : {},
    try(values.squid_root_volume_size, null) != null ? { root_volume_size = values.squid_root_volume_size } : {},
    try(values.squid_root_volume_type, null) != null ? { root_volume_type = values.squid_root_volume_type } : {},
    try(values.squid_port, null) != null ? { squid_port = values.squid_port } : {},
    try(values.squid_generate_ssh_key, null) != null ? { generate_ssh_key = values.squid_generate_ssh_key } : {},
    try(values.squid_cpu_scaling_target_value, null) != null ? { cpu_scaling_target_value = values.squid_cpu_scaling_target_value } : {},
    try(values.squid_memory_scaling_target_value, null) != null ? { memory_scaling_target_value = values.squid_memory_scaling_target_value } : {},
    try(values.squid_instance_refresh_min_healthy_percentage, null) != null ? { instance_refresh_min_healthy_percentage = values.squid_instance_refresh_min_healthy_percentage } : {},
    try(values.squid_instance_refresh_max_healthy_percentage, null) != null ? { instance_refresh_max_healthy_percentage = values.squid_instance_refresh_max_healthy_percentage } : {},
    try(values.squid_instance_refresh_warmup, null) != null ? { instance_refresh_warmup = values.squid_instance_refresh_warmup } : {},
    try(values.squid_instance_refresh_checkpoint_delay, null) != null ? { instance_refresh_checkpoint_delay = values.squid_instance_refresh_checkpoint_delay } : {},
    try(values.wazuh_manager_addr, null) != null ? { wazuh_manager_addr = values.wazuh_manager_addr } : {},
    try(values.wazuh_worker_addr, null) != null ? { wazuh_worker_addr = values.wazuh_worker_addr } : {},
    try(values.wazuh_group, null) != null ? { wazuh_group = values.wazuh_group } : {},
    try(values.wazuh_tag, null) != null ? { wazuh_tag = values.wazuh_tag } : {},
    try(values.sudo_user_list, null) != null ? { sudo_user_list = values.sudo_user_list } : {},
  )
}

unit "envoy-proxy" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/envoy-proxy?ref=unit/aws/envoy-proxy-v0.3.8-v1"
  path   = "envoy-proxy"

  no_dot_terragrunt_stack = true

  values = merge(
    {
      ami_id                = values.ami_id
      virtual_hosts_domains = values.virtual_hosts_domains
    },
    try(values.envoy_instance_type, null) != null ? { instance_type = values.envoy_instance_type } : {},
    try(values.envoy_root_volume_size, null) != null ? { root_volume_size = values.envoy_root_volume_size } : {},
    try(values.envoy_root_volume_type, null) != null ? { root_volume_type = values.envoy_root_volume_type } : {},
    try(values.envoy_min_size, null) != null ? { min_size = values.envoy_min_size } : {},
    try(values.envoy_max_size, null) != null ? { max_size = values.envoy_max_size } : {},
    try(values.envoy_desired_capacity, null) != null ? { desired_capacity = values.envoy_desired_capacity } : {},
    try(values.envoy_cpu_scaling_target_value, null) != null ? { cpu_scaling_target_value = values.envoy_cpu_scaling_target_value } : {},
    try(values.envoy_memory_scaling_target_value, null) != null ? { memory_scaling_target_value = values.envoy_memory_scaling_target_value } : {},
    try(values.envoy_enable_spot_instances, null) != null ? { enable_spot_instances = values.envoy_enable_spot_instances } : {},
    try(values.envoy_spot_instance_percentage, null) != null ? { spot_instance_percentage = values.envoy_spot_instance_percentage } : {},
    try(values.envoy_on_demand_base_capacity, null) != null ? { on_demand_base_capacity = values.envoy_on_demand_base_capacity } : {},
    try(values.envoy_spot_allocation_strategy, null) != null ? { spot_allocation_strategy = values.envoy_spot_allocation_strategy } : {},
    try(values.envoy_enable_capacity_rebalance, null) != null ? { enable_capacity_rebalance = values.envoy_enable_capacity_rebalance } : {},
    try(values.envoy_max_instance_lifetime, null) != null ? { max_instance_lifetime = values.envoy_max_instance_lifetime } : {},
    try(values.envoy_generate_ssh_key, null) != null ? { generate_ssh_key = values.envoy_generate_ssh_key } : {},
    try(values.envoy_health_check_interval, null) != null ? { health_check_interval = values.envoy_health_check_interval } : {},
    try(values.envoy_health_check_timeout, null) != null ? { health_check_timeout = values.envoy_health_check_timeout } : {},
    try(values.envoy_health_check_healthy_threshold, null) != null ? { health_check_healthy_threshold = values.envoy_health_check_healthy_threshold } : {},
    try(values.envoy_health_check_unhealthy_threshold, null) != null ? { health_check_unhealthy_threshold = values.envoy_health_check_unhealthy_threshold } : {},
    try(values.envoy_target_group_deregistration_delay, null) != null ? { target_group_deregistration_delay = values.envoy_target_group_deregistration_delay } : {},
    try(values.base_domain, null) != null ? { base_domain = values.base_domain } : {},
    try(values.cn_base_domain, null) != null ? { cn_base_domain = values.cn_base_domain } : {},
    try(values.opensearch_endpoint, null) != null ? { opensearch_endpoint = values.opensearch_endpoint } : {},
    try(values.opensearch_region, null) != null ? { opensearch_region = values.opensearch_region } : {},
    try(values.envoy_lb_internal, null) != null ? { lb_internal = values.envoy_lb_internal } : {},
    try(values.wazuh_manager_addr, null) != null ? { wazuh_manager_addr = values.wazuh_manager_addr } : {},
    try(values.wazuh_worker_addr, null) != null ? { wazuh_worker_addr = values.wazuh_worker_addr } : {},
    try(values.wazuh_group, null) != null ? { wazuh_group = values.wazuh_group } : {},
    try(values.wazuh_tag, null) != null ? { wazuh_tag = values.wazuh_tag } : {},
    try(values.sudo_user_list, null) != null ? { sudo_user_list = values.sudo_user_list } : {},
  )
}

unit "jump-host" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/jump-host?ref=unit/aws/jump-host-v0.2.1-v1"
  path   = "jump-host"

  no_dot_terragrunt_stack = true

  values = merge(
    { ami_id = values.ami_id },
    try(values.jump_host_instance_type, null) != null ? { instance_type = values.jump_host_instance_type } : {},
    try(values.jump_host_root_volume_size, null) != null ? { root_volume_size = values.jump_host_root_volume_size } : {},
    try(values.jump_host_root_volume_type, null) != null ? { root_volume_type = values.jump_host_root_volume_type } : {},
    try(values.jump_host_log_retention_days, null) != null ? { log_retention_days = values.jump_host_log_retention_days } : {},
    try(values.jump_host_create_ssm_session_preferences, null) != null ? { create_ssm_session_preferences = values.jump_host_create_ssm_session_preferences } : {},
    try(values.jump_host_ssm_idle_session_timeout, null) != null ? { ssm_idle_session_timeout = values.jump_host_ssm_idle_session_timeout } : {},
    try(values.jump_host_ssm_max_session_duration, null) != null ? { ssm_max_session_duration = values.jump_host_ssm_max_session_duration } : {},
    try(values.jump_host_ssm_run_as_user, null) != null ? { ssm_run_as_user = values.jump_host_ssm_run_as_user } : {},
    try(values.jump_host_ssm_cloudwatch_logging_enabled, null) != null ? { ssm_cloudwatch_logging_enabled = values.jump_host_ssm_cloudwatch_logging_enabled } : {},
    try(values.jump_host_ssm_cloudwatch_log_group_retention_days, null) != null ? { ssm_cloudwatch_log_group_retention_days = values.jump_host_ssm_cloudwatch_log_group_retention_days } : {},
    try(values.jump_host_ssm_s3_logging_enabled, null) != null ? { ssm_s3_logging_enabled = values.jump_host_ssm_s3_logging_enabled } : {},
    try(values.jump_host_ssm_s3_bucket_lifecycle_days, null) != null ? { ssm_s3_bucket_lifecycle_days = values.jump_host_ssm_s3_bucket_lifecycle_days } : {},
    try(values.wazuh_manager_addr, null) != null ? { wazuh_manager_addr = values.wazuh_manager_addr } : {},
    try(values.wazuh_worker_addr, null) != null ? { wazuh_worker_addr = values.wazuh_worker_addr } : {},
    try(values.wazuh_group, null) != null ? { wazuh_group = values.wazuh_group } : {},
    try(values.wazuh_tag, null) != null ? { wazuh_tag = values.wazuh_tag } : {},
    try(values.sudo_user_list, null) != null ? { sudo_user_list = values.sudo_user_list } : {},
  )
}

# -----------------------------------------------------------------------------
# Phase 4 — Compute
# -----------------------------------------------------------------------------
unit "eks-01" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/eks-01?ref=unit/aws/eks-01-v0.1.5-v1"
  path   = "application-stack/eks-01"

  no_dot_terragrunt_stack = true

  values = merge(
    {
      cluster_version    = try(values.eks_version, null)
      admin_sso_role_arn = values.admin_role_arn
      admin_access_cidrs = values.admin_access_cidrs
      default_ami_id     = try(values.eks_ami_id, null)
      default_node_os    = try(values.eks_default_node_os, null)
      root_volume_size   = try(values.eks_root_volume_size, null)
      root_volume_type   = try(values.eks_root_volume_type, null)
    },
    try(values.eks_01_addon_versions, null) != null ? { addon_versions = values.eks_01_addon_versions } : {},
    try(values.eks_01_system_nodes, null) != null ? { system_nodes = values.eks_01_system_nodes } : {
      system_nodes = {
        desired_size   = try(values.system_nodes_desired_size, 1)
        min_size       = try(values.system_nodes_min_size, 1)
        max_size       = try(values.system_nodes_max_size, 50)
        instance_types = values.eks_instance_types
      }
    },
    try(values.eks_01_generic_compute, null) != null ? { generic_compute = values.eks_01_generic_compute } : {
      generic_compute = {
        desired_size   = try(values.generic_compute_desired_size, 2)
        min_size       = try(values.generic_compute_min_size, 1)
        max_size       = try(values.generic_compute_max_size, 50)
        instance_types = values.eks_instance_types
      }
    },
    try(values.eks_01_monitoring, null) != null ? { monitoring = values.eks_01_monitoring } : {},
    try(values.eks_01_keymanager, null) != null ? { keymanager = values.eks_01_keymanager } : {},
    try(values.eks_01_auxillary, null) != null ? { auxillary = values.eks_01_auxillary } : {},
  )
}

# -----------------------------------------------------------------------------
# Phase 5 — Kubernetes resources
# -----------------------------------------------------------------------------
unit "eks-resources" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/eks-resources?ref=unit/aws/eks-resources-v0.1.3-v1"
  path   = "application-stack/eks-resources"

  no_dot_terragrunt_stack = true

  values = merge(
    try(values.eks_resources_efs_storage_class_base_path, null) != null ? { efs_storage_class_base_path = values.eks_resources_efs_storage_class_base_path } : {},
    try(values.eks_resources_efs_storage_class_directory_perms, null) != null ? { efs_storage_class_directory_perms = values.eks_resources_efs_storage_class_directory_perms } : {},
    try(values.cluster_autoscaler_image, null) != null ? { cluster_autoscaler_image = values.cluster_autoscaler_image } : {},
    try(values.cluster_autoscaler_image_version, null) != null ? { cluster_autoscaler_image_version = values.cluster_autoscaler_image_version } : {},
    try(values.cluster_autoscaler_service_account_name, null) != null ? { cluster_autoscaler_service_account_name = values.cluster_autoscaler_service_account_name } : {},
    try(values.cluster_autoscaler_requests_cpu, null) != null ? { cluster_autoscaler_requests_cpu = values.cluster_autoscaler_requests_cpu } : {},
    try(values.cluster_autoscaler_requests_memory, null) != null ? { cluster_autoscaler_requests_memory = values.cluster_autoscaler_requests_memory } : {},
    try(values.cluster_autoscaler_limits_cpu, null) != null ? { cluster_autoscaler_limits_cpu = values.cluster_autoscaler_limits_cpu } : {},
    try(values.cluster_autoscaler_limits_memory, null) != null ? { cluster_autoscaler_limits_memory = values.cluster_autoscaler_limits_memory } : {},
    try(values.cluster_autoscaler_log_level, null) != null ? { cluster_autoscaler_log_level = values.cluster_autoscaler_log_level } : {},
    try(values.cluster_autoscaler_expander, null) != null ? { cluster_autoscaler_expander = values.cluster_autoscaler_expander } : {},
    try(values.cluster_autoscaler_skip_local_storage, null) != null ? { cluster_autoscaler_skip_local_storage = values.cluster_autoscaler_skip_local_storage } : {},
    try(values.cluster_autoscaler_skip_system_pods, null) != null ? { cluster_autoscaler_skip_system_pods = values.cluster_autoscaler_skip_system_pods } : {},
  )
}

unit "utils-load-balancer" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/utils-load-balancer?ref=unit/aws/utils-load-balancer-v0.1.1-v1"
  path   = "application-stack/utils-load-balancer"

  no_dot_terragrunt_stack = true

  values = merge(
    try(values.utils_load_balancer_create_alb, null) != null ? { create_alb = values.utils_load_balancer_create_alb } : {},
  )
}

# -----------------------------------------------------------------------------
# Phase 6 — Apps (Kubernetes workloads)
# -----------------------------------------------------------------------------
unit "alb-controller" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/alb-controller?ref=unit/aws/alb-controller-v0.1.2-v1"
  path   = "application-stack/apps/alb-controller"

  no_dot_terragrunt_stack = true

  values = merge(
    try(values.alb_controller_namespace, null) != null ? { alb_controller_namespace = values.alb_controller_namespace } : {},
    try(values.alb_controller_service_account_name, null) != null ? { alb_controller_service_account_name = values.alb_controller_service_account_name } : {},
    try(values.alb_controller_create_service_account, null) != null ? { create_alb_controller_service_account = values.alb_controller_create_service_account } : {},
    try(values.alb_controller_create_helm_release, null) != null ? { create_helm_release = values.alb_controller_create_helm_release } : {},
  )
}

unit "external-secrets" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/external-secrets?ref=unit/aws/external-secrets-v0.1.1-v1"
  path   = "application-stack/apps/external-secrets"

  no_dot_terragrunt_stack = true

  values = merge(
    try(values.external_secrets_namespace, null) != null ? { kubernetes_namespace = values.external_secrets_namespace } : {},
    try(values.external_secrets_service_account_name, null) != null ? { service_account_name = values.external_secrets_service_account_name } : {},
  )
}

unit "istio" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/istio?ref=unit/aws/istio-v0.1.4-v1"
  path   = "application-stack/apps/istio"

  no_dot_terragrunt_stack = true

  values = merge(
    { host_domains = values.istio_host_domains },
    try(values.istio_namespace, null) != null ? { istio_namespace = values.istio_namespace } : {},
    try(values.istio_create_helm_releases, null) != null ? { create_helm_releases = values.istio_create_helm_releases } : {},
  )
}

unit "otel" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/otel?ref=unit/aws/otel-v0.1.0-v1"
  path   = "application-stack/apps/otel"

  no_dot_terragrunt_stack = true

  values = merge(
    try(values.otel_namespace, null) != null ? { kubernetes_namespace = values.otel_namespace } : {},
    try(values.otel_service_account_name, null) != null ? { service_account_name = values.otel_service_account_name } : {},
  )
}

unit "vector-dr" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/vector-dr?ref=unit/aws/vector-dr-v0.1.1-v1"
  path   = "application-stack/apps/vector-dr"

  no_dot_terragrunt_stack = true

  values = merge(
    try(values.vector_dr_namespace, null) != null ? { kubernetes_namespace = values.vector_dr_namespace } : {},
    try(values.vector_dr_service_account_name, null) != null ? { service_account_name = values.vector_dr_service_account_name } : {},
    try(values.vector_dr_s3_force_destroy, null) != null ? { s3_force_destroy = values.vector_dr_s3_force_destroy } : {},
    try(values.vector_dr_s3_versioning_enabled, null) != null ? { s3_versioning_enabled = values.vector_dr_s3_versioning_enabled } : {},
    try(values.vector_dr_sqs_message_retention, null) != null ? { sqs_message_retention = values.vector_dr_sqs_message_retention } : {},
    try(values.vector_dr_sqs_receive_wait_time, null) != null ? { sqs_receive_wait_time = values.vector_dr_sqs_receive_wait_time } : {},
    try(values.vector_dr_sqs_visibility_timeout, null) != null ? { sqs_visibility_timeout = values.vector_dr_sqs_visibility_timeout } : {},
  )
}

unit "loki" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/loki?ref=unit/aws/loki-v0.1.3-v1"
  path   = "application-stack/apps/loki"

  no_dot_terragrunt_stack = true

  values = merge(
    try(values.loki_namespace, null) != null ? { kubernetes_namespace = values.loki_namespace } : {},
    try(values.loki_service_account_name, null) != null ? { service_account_name = values.loki_service_account_name } : {},
    try(values.loki_s3_force_destroy, null) != null ? { s3_force_destroy = values.loki_s3_force_destroy } : {},
    try(values.loki_s3_versioning_enabled, null) != null ? { s3_versioning_enabled = values.loki_s3_versioning_enabled } : {},
    try(values.loki_s3_lifecycle_expiration_days, null) != null ? { s3_lifecycle_expiration_days = values.loki_s3_lifecycle_expiration_days } : {},
  )
}

unit "grafana" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/grafana?ref=unit/aws/grafana-v0.1.3-v1"
  path   = "application-stack/apps/grafana"

  no_dot_terragrunt_stack = true

  values = merge(
    { base_domain = values.base_domain },
    try(values.grafana_namespace, null) != null ? { kubernetes_namespace = values.grafana_namespace } : {},
    try(values.grafana_service_account_name, null) != null ? { service_account_name = values.grafana_service_account_name } : {},
    try(values.grafana_database_engine_version, null) != null ? { database_engine_version = values.grafana_database_engine_version } : {},
    try(values.grafana_db_instance_class, null) != null ? { grafana_db_instance_class = values.grafana_db_instance_class } : {},
    try(values.grafana_database_backup_retention_period, null) != null ? { database_backup_retention_period = values.grafana_database_backup_retention_period } : {},
    try(values.grafana_database_deletion_protection, null) != null ? { database_deletion_protection = values.grafana_database_deletion_protection } : {},
    try(values.grafana_database_apply_immediately, null) != null ? { database_apply_immediately = values.grafana_database_apply_immediately } : {},
    try(values.grafana_database_skip_final_snapshot, null) != null ? { database_skip_final_snapshot = values.grafana_database_skip_final_snapshot } : {},
  )
}

unit "ratelimiter" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/ratelimiter?ref=unit/aws/ratelimiter-v0.1.0-v1"
  path   = "application-stack/apps/ratelimiter"

  no_dot_terragrunt_stack = true

  values = merge(
    try(values.ratelimiter_namespace, null) != null ? { kubernetes_namespace = values.ratelimiter_namespace } : {},
    try(values.ratelimiter_service_account_name, null) != null ? { service_account_name = values.ratelimiter_service_account_name } : {},
    try(values.ratelimiter_cache_engine_version, null) != null ? { cache_engine_version = values.ratelimiter_cache_engine_version } : {},
    try(values.ratelimiter_cache_parameter_group_name, null) != null ? { cache_parameter_group_name = values.ratelimiter_cache_parameter_group_name } : {},
    try(values.ratelimiter_cache_node_type, null) != null ? { cache_node_type = values.ratelimiter_cache_node_type } : {},
    try(values.ratelimiter_cache_num_clusters, null) != null ? { cache_num_clusters = values.ratelimiter_cache_num_clusters } : {},
    try(values.ratelimiter_cache_maintenance_window, null) != null ? { cache_maintenance_window = values.ratelimiter_cache_maintenance_window } : {},
    try(values.ratelimiter_cache_snapshot_window, null) != null ? { cache_snapshot_window = values.ratelimiter_cache_snapshot_window } : {},
    try(values.ratelimiter_cache_snapshot_retention_limit, null) != null ? { cache_snapshot_retention_limit = values.ratelimiter_cache_snapshot_retention_limit } : {},
    try(values.ratelimiter_cache_apply_immediately, null) != null ? { cache_apply_immediately = values.ratelimiter_cache_apply_immediately } : {},
  )
}

unit "hyperswitch" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/hyperswitch?ref=unit/aws/hyperswitch-v0.1.1-v1"
  path   = "application-stack/apps/hyperswitch"

  no_dot_terragrunt_stack = true

  values = merge(
    {
      ses_email_role_arn = try(values.ses_email_role_arn, null)
    },
    try(values.hyperswitch_namespace, null) != null ? { kubernetes_namespace = values.hyperswitch_namespace } : {},
    try(values.hyperswitch_service_account_name, null) != null ? { service_account_name = values.hyperswitch_service_account_name } : {},
    try(values.hyperswitch_s3_dashboard_themes_versioning_enabled, null) != null ? { s3_dashboard_themes_versioning_enabled = values.hyperswitch_s3_dashboard_themes_versioning_enabled } : {},
    try(values.hyperswitch_s3_dashboard_themes_force_destroy, null) != null ? { s3_dashboard_themes_force_destroy = values.hyperswitch_s3_dashboard_themes_force_destroy } : {},
    try(values.hyperswitch_s3_file_uploads_versioning_enabled, null) != null ? { s3_file_uploads_versioning_enabled = values.hyperswitch_s3_file_uploads_versioning_enabled } : {},
    try(values.hyperswitch_s3_file_uploads_force_destroy, null) != null ? { s3_file_uploads_force_destroy = values.hyperswitch_s3_file_uploads_force_destroy } : {},
  )
}

unit "decision-engine" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/decision-engine?ref=unit/aws/decision-engine-v0.1.3-v1"
  path   = "application-stack/apps/decision-engine"

  no_dot_terragrunt_stack = true

  values = merge(
    {
      ses_email_role_arn = try(values.ses_email_role_arn, null)
    },
    try(values.decision_engine_namespace, null) != null ? { kubernetes_namespace = values.decision_engine_namespace } : {},
    try(values.decision_engine_service_account_name, null) != null ? { service_account_name = values.decision_engine_service_account_name } : {},
    try(values.decision_engine_s3_force_destroy, null) != null ? { s3_force_destroy = values.decision_engine_s3_force_destroy } : {},
    try(values.decision_engine_s3_versioning_enabled, null) != null ? { s3_versioning_enabled = values.decision_engine_s3_versioning_enabled } : {},
    try(values.decision_engine_s3_noncurrent_version_expiration_days, null) != null ? { s3_noncurrent_version_expiration_days = values.decision_engine_s3_noncurrent_version_expiration_days } : {},
  )
}

unit "superposition" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/superposition?ref=unit/aws/superposition-v0.1.7-v1"
  path   = "application-stack/apps/superposition"

  no_dot_terragrunt_stack = true

  values = merge(
    { base_domain = values.base_domain },
    try(values.superposition_namespace, null) != null ? { kubernetes_namespace = values.superposition_namespace } : {},
    try(values.superposition_service_account_name, null) != null ? { service_account_name = values.superposition_service_account_name } : {},
    try(values.superposition_engine_version, null) != null ? { engine_version = values.superposition_engine_version } : {},
    try(values.superposition_db_cluster_parameter_group_name, null) != null ? { db_cluster_parameter_group_name = values.superposition_db_cluster_parameter_group_name } : {},
    try(values.superposition_db_parameter_group_name, null) != null ? { db_parameter_group_name = values.superposition_db_parameter_group_name } : {},
    try(values.superposition_db_instance_class, null) != null ? { db_instance_class = values.superposition_db_instance_class } : {},
    try(values.superposition_backup_retention_period, null) != null ? { backup_retention_period = values.superposition_backup_retention_period } : {},
    try(values.superposition_skip_final_snapshot, null) != null ? { skip_final_snapshot = values.superposition_skip_final_snapshot } : {},
    try(values.superposition_deletion_protection, null) != null ? { deletion_protection = values.superposition_deletion_protection } : {},
    try(values.superposition_apply_immediately, null) != null ? { apply_immediately = values.superposition_apply_immediately } : {},
  )
}

# -----------------------------------------------------------------------------
# Phase 7 — Security rules (apply last)
# -----------------------------------------------------------------------------
unit "security-rules" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/security-rules?ref=unit/aws/security-rules-v0.2.1-v1"
  path   = "security-rules"

  no_dot_terragrunt_stack = true

  values = {
    # No vpc_id -> local.has_vpc_network = true -> reads the created vpc-network unit.
    # Every enable_* toggle is left at its catalog default (true) for full parity;
    # only the internal-only, not-yet-modeled components stay off by default:
    #   enable_encryption_service, enable_auth_proxy, enable_wazuh_endpoints
  }
}
