variable "environment" {
  description = "Environment name (dev/integ/prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "ami_id" {
  description = "Custom AMI ID for locker instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "user_data" {
  description = "Raw user data to provide to locker EC2 instances"
  type        = string
  default     = null
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
  validation {
    condition     = var.instance_count >= 1
    error_message = "Instance count must be at least 1"
  }
}

variable "locker_port" {
  description = "Port number for the locker service"
  type        = number
  default     = 8080
}

variable "key_name" {
  description = "SSH key pair name. Required if create_key_pair is false. If create_key_pair is true and this is provided, it will be used as the name for the new key pair; otherwise an auto-generated name will be used"
  type        = string
  default     = null
  validation {
    condition     = var.create_key_pair || var.key_name != null
    error_message = "key_name must be provided when create_key_pair is false"
  }
}

variable "create_key_pair" {
  description = "Whether to create a new SSH key pair. If true, public_key must be provided"
  type        = bool
  default     = false
}

variable "public_key" {
  description = "Public key material for creating new SSH key pair. Optional - if not provided when create_key_pair is true, a new key pair will be auto-generated and the private key will be stored in SSM Parameter Store"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "locker_subnet_ids" {
  description = "List of subnet IDs for the locker instances. Instances will be distributed across these subnets."
  type        = list(string)
}

variable "alb_subnet_ids" {
  description = "List of subnet IDs for the Application Load Balancer. At least two subnets in two different Availability Zones are required."
  type        = list(string)

  validation {
    condition     = length(var.alb_subnet_ids) >= 2
    error_message = "At least two subnets in two different Availability Zones must be specified for the ALB."
  }
}

variable "alb_listeners" {
  description = "ALB listener configurations for the Application Load Balancer"
  type = map(object({
    port             = number
    protocol         = string
    target_group_arn = optional(string) # If not provided, will use the default locker target group
    certificate_arn  = optional(string) # Required for HTTPS protocol
  }))
  default = {
    "http" = {
      port     = 80
      protocol = "HTTP"
    }
  }
  validation {
    condition = alltrue([
      for key, listener in var.alb_listeners :
      contains(["HTTP", "HTTPS"], listener.protocol)
    ])
    error_message = "Listener protocol must be one of: HTTP, HTTPS"
  }
}

variable "create_locker_database" {
  description = "Create a RDS Aurora PostgreSQL database for Locker"
  type        = bool
  default     = false
}

variable "database_config" {
  description = "Configuration object for the RDS Aurora PostgreSQL database"
  type = object({
    subnet_ids                            = list(string)
    cluster_identifier                    = optional(string, null)
    cluster_identifier_prefix             = optional(string, null)
    database_name                         = optional(string, null)
    engine                                = optional(string, "aurora-postgresql")
    engine_version                        = optional(string, null)
    engine_mode                           = optional(string, "provisioned")
    engine_lifecycle_support              = optional(string, "open-source-rds-extended-support")
    cluster_scalability_type              = optional(string, null)
    master_username                       = string
    master_password                       = optional(string, null)
    manage_master_user_password           = optional(bool, null)
    master_user_secret_kms_key_id         = optional(string, null)
    db_cluster_instance_class             = optional(string, null)
    availability_zones                    = list(string)
    allocated_storage                     = optional(number, null)
    storage_type                          = optional(string, "aurora-iopt1")
    iops                                  = optional(number, null)
    network_type                          = optional(string, "IPV4")
    port                                  = optional(number, 5432)
    create_db_subnet_group                = optional(bool, true)
    db_subnet_group_name                  = optional(string, null)
    vpc_security_group_ids                = optional(list(string), [])
    db_cluster_parameter_group_name       = optional(string, "default.aurora-postgresql17")
    db_instance_parameter_group_name      = optional(string, null)
    backup_retention_period               = optional(number, 7)
    preferred_backup_window               = optional(string, "00:51-01:21")
    preferred_maintenance_window          = optional(string, "thu:00:12-thu:00:42")
    skip_final_snapshot                   = optional(bool, true)
    final_snapshot_identifier             = optional(string, null)
    snapshot_identifier                   = optional(string, null)
    copy_tags_to_snapshot                 = optional(bool, false)
    storage_encrypted                     = optional(bool, true)
    kms_key_id                            = optional(string, null)
    deletion_protection                   = optional(bool, false)
    delete_automated_backups              = optional(bool, true)
    iam_database_authentication_enabled   = optional(bool, false)
    iam_roles                             = optional(list(string), [])
    domain                                = optional(string, null)
    domain_iam_role_name                  = optional(string, null)
    allow_major_version_upgrade           = optional(bool, null)
    apply_immediately                     = optional(bool, null)
    enabled_cloudwatch_logs_exports       = optional(list(string), ["postgresql"])
    performance_insights_enabled          = optional(bool, false)
    performance_insights_kms_key_id       = optional(string, null)
    performance_insights_retention_period = optional(number, 0)
    monitoring_interval                   = optional(number, 0)
    monitoring_role_arn                   = optional(string, null)
    database_insights_mode                = optional(string, "standard")
    enable_http_endpoint                  = optional(bool, false)
    enable_local_write_forwarding         = optional(bool, null)
    replication_source_identifier         = optional(string, null)
    source_region                         = optional(string, null)
    backtrack_window                      = optional(number, 0)
    ca_certificate_identifier             = optional(string, null)
    db_system_id                          = optional(string, null)
    create_security_group                 = optional(bool, true)
    security_group_name                   = optional(string, null)
    security_group_description            = optional(string, null)
    scaling_configuration                 = optional(any, null)
    serverlessv2_scaling_configuration    = optional(any, null)
    restore_to_point_in_time              = optional(any, null)
    s3_import                             = optional(any, null)
    create_global_cluster                 = optional(bool, false)
    global_cluster_identifier             = optional(string, null)
    global_deletion_protection            = optional(bool, true)
    enable_global_write_forwarding        = optional(bool, false)
    use_existing_as_global_primary        = optional(bool, false)
    source_db_cluster_identifier          = optional(string, null)
    create_custom_parameter_group         = optional(bool, false)
    custom_parameter_group_name           = optional(string, null)
    custom_parameter_group_family         = optional(string, null)
    custom_parameter_group_description    = optional(string, null)
    custom_parameter_group_parameters     = optional(list(map(string)), [])
    cluster_instances = optional(map(object({
      identifier                            = optional(string)
      identifier_prefix                     = optional(string)
      instance_class                        = string
      engine                                = optional(string)
      engine_version                        = optional(string)
      publicly_accessible                   = optional(bool)
      db_parameter_group_name               = optional(string)
      apply_immediately                     = optional(bool)
      monitoring_role_arn                   = optional(string)
      monitoring_interval                   = optional(number)
      promotion_tier                        = optional(number)
      availability_zone                     = optional(string)
      preferred_backup_window               = optional(string)
      preferred_maintenance_window          = optional(string)
      auto_minor_version_upgrade            = optional(bool)
      performance_insights_enabled          = optional(bool)
      performance_insights_kms_key_id       = optional(string)
      performance_insights_retention_period = optional(number)
      copy_tags_to_snapshot                 = optional(bool)
      ca_cert_identifier                    = optional(string)
      custom_iam_instance_profile           = optional(string)
      force_destroy                         = optional(bool)
      tags                                  = optional(map(string))
    })), {})
    tags = optional(map(string), {})
  })
  default = null
}

variable "kms" {
  description = "KMS key configuration. Set to {} to disable KMS key and policy. Set create=true to create key, or create=false with key_arn to use existing key. Policy and tags are handled internally by the module."
  type = object({
    # Key source: either create new or use existing
    create   = optional(bool, false)      # Set true to create KMS key, false to use existing
    key_arns = optional(list(string), []) # Existing KMS key ARN (used when create=false)

    # Key creation settings (used when create=true)
    description  = optional(string, null)
    multi_region = optional(bool, false)

    # Replica key settings
    create_replica           = optional(bool, false)
    create_replica_external  = optional(bool, false)
    primary_key_arn          = optional(string, null)
    primary_external_key_arn = optional(string, null)

    # External key settings
    create_external     = optional(bool, false)
    key_material_base64 = optional(string, null)
    valid_to            = optional(string, null)

    # Key specifications
    key_usage                = optional(string, null)
    customer_master_key_spec = optional(string, null)
    key_spec                 = optional(string, null)
    deletion_window_in_days  = optional(number, null)

    # Key settings
    is_enabled                         = optional(bool, null)
    enable_key_rotation                = optional(bool, true)
    rotation_period_in_days            = optional(number, null)
    bypass_policy_lockout_safety_check = optional(bool, null)

    # Aliases
    aliases                 = optional(list(string), [])
    aliases_use_name_prefix = optional(bool, false)

    # Access control (for key policy)
    key_administrators = optional(list(string), [])
    key_users          = optional(list(string), [])
    key_service_users  = optional(list(string), [])
    key_owners         = optional(list(string), [])
  })
  default = {}
}
