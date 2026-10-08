include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/locker?ref=locker-v0.2.12"
}

locals {
  extra_atlantis_dependencies = [
    "templates/userdata.sh"
  ]
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    locker_database_subnet_ids = ["mock-locker_database_subnet_ids"]
    locker_server_subnet_ids   = ["mock-locker_server_subnet_ids"]
    vpc_id                     = "vpc-mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "locker-primary" {
  config_path = try(values.primary_locker_config_path, try("../../${values.primary_region}/locker", null))
  enabled     = try(values.is_passive, false)

  mock_outputs = {
    db_cluster_arn                          = "arn:aws:mock:::123456789012:mock/mock"
    db_global_cluster_id                    = "mock-db_global_cluster_id"
    kms_key_arn                             = "arn:aws:kms:us-east-1:123456789012:key/mock"
    elasticache_global_replication_group_id = "mock-elasticache_global_replication_group_id"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  environment  = include.root.locals.environment.full
  region       = include.root.locals.region
  project_name = include.root.locals.project_name
  vpc_id       = dependency.vpc.outputs.vpc_id

  locker_subnet_ids = dependency.vpc.outputs.locker_server_subnet_ids

  alb_subnet_ids = dependency.vpc.outputs.locker_server_subnet_ids
  # Get latest Amazon Linux 2023 AMI for eu-west-1
  # Run: aws ssm get-parameter --name "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64" --region eu-west-1 --query Parameter.Value
  ami_id = values.ami_id

  # Wazuh enrollment and sudo users are environment-specific; supplied via stack values.
  user_data = replace(replace(replace(replace(replace(replace(replace(
    file("${get_terragrunt_dir()}/templates/userdata.sh"),
    "{{update-wazuh}}", try(values.wazuh_manager_addr, "") != "" ? "Enable" : "Disable"),
    "{{wazuh-manager-addr}}", try(values.wazuh_manager_addr, "NA")),
    "{{wazuh-worker-addr}}", try(values.wazuh_worker_addr, "NA")),
    "{{wazuh-group}}", try(values.wazuh_group, "NA")),
    "{{wazuh-tag}}", try(values.wazuh_tag, "NA")),
    "{{sudo-user-list}}", try(values.sudo_user_list, "ubuntu")),
  "{{region}}", include.root.locals.region)

  instance_type   = try(values.instance_type, "t3.medium")
  create_key_pair = true
  key_name        = "${include.root.locals.environment.full}-locker-key"

  additional_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

  alb_listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
    }
  }

  kms = {
    create              = true
    description         = "KMS key for Locker multi-region encryption"
    multi_region        = true
    create_replica      = try(values.is_passive, false)
    primary_key_arn     = try(dependency.locker-primary.outputs.kms_key_arn, null)
    enable_key_rotation = true
    aliases             = ["locker-key-${include.root.locals.environment.full}"]
  }

  create_locker_database = true

  database_config = {
    subnet_ids               = dependency.vpc.outputs.locker_database_subnet_ids
    engine                   = "aurora-postgresql"
    engine_version           = try(values.engine_version, "17.9")
    engine_mode              = "provisioned"
    engine_lifecycle_support = "open-source-rds-extended-support"

    # Enable global cluster
    create_global_cluster          = !try(values.is_passive, false)
    global_deletion_protection     = !try(values.is_passive, false)
    use_existing_as_global_primary = !try(values.is_passive, false)

    # Read Replica Configuration
    global_cluster_identifier     = try(dependency.locker-primary.outputs.db_global_cluster_id, null)
    replication_source_identifier = try(dependency.locker-primary.outputs.db_cluster_arn, null)
    source_region                 = try(values.primary_region, null)

    # KMS Key Configuration - Create a new KMS key for this replica cluster
    kms = {
      create              = try(values.is_passive, false)
      multi_region        = true
      enable_key_rotation = true
    }

    # master_username          = "postgres"
    # master_password                  = "<redacted>"
    # Alternatively, fetch the master password from an existing AWS Secrets Manager secret
    # (requires locker module with database-v0.1.7 or later):
    # master_password_secretsmanager_secret_id  = "<secret ARN or name>"
    # master_password_secretsmanager_secret_key = "password" # only if the secret is a JSON object
    availability_zones              = ["${include.root.locals.region}a", "${include.root.locals.region}b"]
    allocated_storage               = null
    storage_type                    = try(values.storage_type, "aurora-iopt1")
    network_type                    = "IPV4"
    port                            = 5432
    create_db_subnet_group          = true
    db_cluster_parameter_group_name = "default.aurora-postgresql17"
    # Custom Parameter Group Configuration - Disable SSL
    create_custom_parameter_group = true
    custom_parameter_group_name   = "${include.root.locals.environment.short}-locker-db-parameter-group"
    custom_parameter_group_family = "aurora-postgresql17"
    custom_parameter_group_parameters = [
      {
        name         = "rds.force_ssl"
        value        = "0"
        apply_method = "immediate"
      }
    ]
    backup_retention_period               = try(values.backup_retention_period, 7)
    preferred_backup_window               = try(values.backup_window, "02:03-02:33")
    preferred_maintenance_window          = try(values.maintenance_window, "tue:00:25-tue:00:55")
    skip_final_snapshot                   = true
    copy_tags_to_snapshot                 = true
    storage_encrypted                     = true
    deletion_protection                   = true
    snapshot_identifier                   = null
    kms_key_id                            = null
    apply_immediately                     = true
    delete_automated_backups              = true
    enabled_cloudwatch_logs_exports       = []
    performance_insights_enabled          = false
    performance_insights_retention_period = 0
    monitoring_interval                   = 0
    database_insights_mode                = "standard"
    enable_http_endpoint                  = false
    backtrack_window                      = 0
    create_security_group                 = true

    cluster_instances = try(values.cluster_instances, {
      instance_a = {
        instance_class                        = try(values.db_instance_class, "db.r6g.large")
        promotion_tier                        = 0
        availability_zone                     = "${include.root.locals.region}a"
        db_parameter_group_name               = "default.aurora-postgresql17"
        auto_minor_version_upgrade            = true
        publicly_accessible                   = false
        copy_tags_to_snapshot                 = false
        monitoring_interval                   = 0
        performance_insights_enabled          = false
        performance_insights_retention_period = 0
      }
    })
  }

  log_retention_days = try(values.log_retention_days, 30)

  # ElastiCache (Valkey) for locker — opt-in via values, wired the same way as
  # database_config above and mirroring the standalone catalog elasticache unit.
  create_locker_elasticache = try(values.create_locker_elasticache, false)

  elasticache_config = {
    subnet_ids = try(values.cache_subnet_ids, dependency.vpc.outputs.locker_database_subnet_ids)

    # Create new subnet group and security group
    create_elasticache_subnet_group = true
    create_security_group           = true

    # Engine Configuration. Defaults to Valkey; a secondary joining a legacy
    # Redis global datastore must match the primary's engine, version and
    # parameter-group family, so these are overridable via values.
    engine               = try(values.cache_engine, "valkey")
    engine_version       = try(values.cache_engine_version, "8.2")
    parameter_group_name = try(values.cache_parameter_group_name, "default.valkey8.cluster.on")
    port                 = 6379

    # Node Configuration
    node_type            = try(values.cache_node_type, "cache.m6g.large")
    cluster_mode         = "enabled"
    num_node_groups      = try(values.cache_num_node_groups, 1)
    data_tiering_enabled = false

    # High Availability
    automatic_failover_enabled = true
    multi_az_enabled           = true

    # Network Configuration
    ip_discovery = "ipv4"
    network_type = "ipv4"

    # Security. kms_key_id left null so the module defaults to the locker's
    # own KMS key, matching the standalone locker-elasticache wiring.
    at_rest_encryption_enabled = true
    kms_key_id                 = null
    transit_encryption_enabled = false

    # Maintenance & Backup
    maintenance_window         = try(values.cache_maintenance_window, "mon:04:00-mon:05:00")
    snapshot_window            = try(values.cache_snapshot_window, "23:30-00:30")
    snapshot_retention_limit   = try(values.cache_snapshot_retention_limit, 7)
    auto_minor_version_upgrade = true
    apply_immediately          = true

    # Log Delivery (engine/slow logs to CloudWatch or Kinesis Firehose).
    # Ignored on passive secondaries by the module. Unless the stack sets
    # create_log_groups = false, the module also creates the CloudWatch log
    # groups named as destinations.
    log_delivery = merge(
      { create_log_groups = true },
      try(values.cache_log_delivery, { configuration = [] })
    )

    # Global Replication Configuration (secondary region joins the primary
    # locker's global datastore, same pattern as database_config above)
    create_global_replication_group = !try(values.is_passive, false)
    global_replication_group_id     = try(values.is_passive, false) ? dependency.locker-primary.outputs.elasticache_global_replication_group_id : try(values.cache_global_replication_group_id, null)
    global_deletion_protection      = true
    is_secondary_region             = try(values.is_passive, false)
    use_existing_as_global_primary  = false
    source_replication_group_id     = null

    # Node Group Configuration (1 shard with 1 replica across AZ a/b)
    node_group_configuration = try(values.cache_node_group_configuration, [
      {
        node_group_id              = "0001"
        primary_availability_zone  = "${include.root.locals.region}a"
        replica_availability_zones = ["${include.root.locals.region}b"]
        replica_count              = try(values.cache_replicas_per_node_group, 1)
        slots                      = "0-16383"
      }
    ])
  }

  tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    Component   = "locker"
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }
}
